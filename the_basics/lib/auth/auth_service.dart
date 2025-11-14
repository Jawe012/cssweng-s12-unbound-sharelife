import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:the_basics/core/utils/profile_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing Supabase connection...');
      
      // Simple health check - try to get session (doesn't require auth)
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('Connection test successful. Current session: ${session.user.id}');
      } else {
        debugPrint('Connection test successful. No current session.');
      }
      return true;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String input_credential, String password) async {
    String? email_credential;

  debugPrint('[signIn] input credential: $input_credential');

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input_credential)) {
      // input is not an email (treat as username)
        debugPrint('[signIn] Detected username input. Looking up email by username...');
      try {
        final userByUsername = await _supabase
            .from('members')
            .select('email_address')
            .eq('username', input_credential)
            .maybeSingle();

  debugPrint('[signIn] userByUsername result: $userByUsername');

        final staffByUsername = await _supabase
            .from('staff')
            .select('email_address')
            .eq('username', input_credential)
            .maybeSingle();

  debugPrint('[signIn] staffByUsername result: $staffByUsername');

        if (userByUsername != null && userByUsername['email_address'] != null) {
          email_credential = userByUsername['email_address'];
        } else if (staffByUsername != null && staffByUsername['email_address'] != null) {
          email_credential = staffByUsername['email_address'];
        } else {
          debugPrint('[signIn] No user found with that username');
          return Future.error('No user found with that username');
        }
      } catch (e) {
  debugPrint('[signIn] Error fetching user by username: $e');
        return Future.error('Error fetching user by username: $e');
      }
    } else {
      // input is an email
  email_credential = input_credential.trim().toLowerCase();
  debugPrint('[signIn] Detected email input. Using email: $email_credential');
    }

  debugPrint('[signIn] Calling Supabase signInWithPassword for $email_credential');
    try {
      // Pre-check role by email to prevent a signed-in session from being used
      try {
        if (email_credential != null && email_credential.isNotEmpty) {
          dynamic staffRec = await _supabase.from('staff').select('role').eq('email_address', email_credential).maybeSingle();
          String? preRole = staffRec != null && staffRec['role'] != null ? staffRec['role'].toString() : null;
          if (preRole == null) {
            dynamic memberRec = await _supabase.from('members').select('role').eq('email_address', email_credential).maybeSingle();
            preRole = memberRec != null && memberRec['role'] != null ? memberRec['role'].toString() : null;
          }
          if (preRole != null && preRole.toLowerCase() == 'revoked') {
            debugPrint('[signIn] Pre-check: account revoked for $email_credential');
            return Future.error('Your account has been revoked. Contact an administrator for assistance.');
          }
        }
      } catch (e) {
        debugPrint('[signIn] Pre-check role query failed: $e');
        // continue to attempt sign-in; will perform post-check too
      }

      final resp = await _supabase.auth.signInWithPassword(
        email: email_credential,
        password: password,
      );
      debugPrint('[signIn] Supabase response: $resp');

      // After successful sign in, double-check role and block revoked accounts
      try {
        final role = await getUserRole();
        debugPrint('[signIn] Resolved role for user: $role');
        if (role != null && role.toLowerCase() == 'revoked') {
          // immediately sign out to prevent access
          await _supabase.auth.signOut();
          debugPrint('[signIn] Access denied: account revoked');
          return Future.error('Your account has been revoked. Contact an administrator for assistance.');
        }
      } catch (e) {
        debugPrint('[signIn] Error while checking role after sign-in: $e');
        // allow sign-in to continue if role check fails unexpectedly
      }

      return resp;
    } catch (e) {
      debugPrint('[signIn] Supabase signIn error: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final email = user.email!; // null safety

    try {
      final staffRecord = await _supabase
          .from('staff')
          .select('role')
          .eq('email_address', email)
          .maybeSingle();

      if (staffRecord != null && staffRecord['role'] != null) {
        return staffRecord['role'] as String;
      }

      final memberRecord = await _supabase
          .from('members')
          .select('role')
          .eq('email_address', email)
          .maybeSingle();

      return memberRecord?['role'] as String?;
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      return null;
    }
  }

  final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZ21vdmtpb3Vicml6YWpzdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMzk3MzIsImV4cCI6MjA3NDgxNTczMn0.PBXfbH3n7yTVwZs_e9li_U9F8YirKTl4Wl3TVr1o0gw';
  
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    required String username,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String contactNo,
  }) async {
    try {
      // Check if user already exists
      final exists = await checkUserExists(email, username: username);
      if (exists) {
    debugPrint('[staffSignUp] User already exists with that email/username: $email / $username');
        return Future.error('User already exists with that email/username');
      }

      // Validate password using central helper
      final pwErr = validatePassword(password);
      if (pwErr != null) {
        debugPrint('[signUp] Password validation failed: $pwErr');
        return Future.error(pwErr);
      }
      
      // Password validated; proceed to save pending profile and sign up
      debugPrint('[signUp] Saving pending profile for: $email');
      await ProfileStorage.savePendingProfile({
        'email': email.trim().toLowerCase(),
        'username': username.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'date_of_birth': dateOfBirth.trim(),
        'contact_no': contactNo.trim(),
        'role': 'member', // mark as member so claim logic knows where to insert
      });

      // Perform auth signup
      debugPrint('[signUp] Calling Supabase signUp for: $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('[signUp] Supabase signUp response: ${response.user?.id}, response: $response');
      return response;
    } catch (e) {
      debugPrint('[staffSignUp] Error checking existing user: $e');
      return Future.error('Error checking existing user: $e');
    }
  }

  /// Validate a password against the project's policy.
  /// Returns null if the password is valid, otherwise returns a human-friendly error
  /// message suitable for showing to users.
  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // Require at least one lowercase, one uppercase, one digit and one special character
    final passComplexity = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*.,?]).+$');
    if (!passComplexity.hasMatch(password)) {
      return 'Password must have an uppercase letter, a lowercase letter, a number, and a special character (e.g. !@#\$%^&*.,?)';
    }

    return null;
  }

  // Reset user password
  // If `redirectTo` is provided, Supabase will include it in the recovery link.
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      debugPrint('[passwordReset] Sending password reset for $normalizedEmail (redirectTo: $redirectTo)');
      // Supabase Flutter provides a reset helper; some versions accept redirectTo.
      await _supabase.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: redirectTo,
      );
      debugPrint('[passwordReset] Reset email request submitted.');
    } catch (e) {
      debugPrint('[passwordReset] Error sending reset email: $e');
      rethrow;
    }
  }

  // Update authenticated user's password. Call this after the user follows the
  // recovery link and you have them enter a new password in-app.
  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('[updatePassword] Updating password for current user');
      // UserAttributes is provided by supabase_flutter; set the password field.
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('[updatePassword] Password update request submitted.');
    } catch (e) {
      debugPrint('[updatePassword] Error updating password: $e');
      rethrow;
    }
  }


  // Staff sign up using same pending-profile flow as members
  Future<AuthResponse> staffSignUp(
    String email,
    String password, {
    required String username,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String contactNo,
    String role = 'encoder',
  }) async {

    try {
      // Check if user already exists
      final exists = await checkUserExists(email, username: username);

      if (exists) {
        print('[staffSignUp] User already exists with that email/username: $email / $username');
        return Future.error('User already exists with that email/username');
      }

      final pwErr = validatePassword(password);
      if (pwErr != null) {
        print('[staffSignUp] Password validation failed: $pwErr');
        return Future.error(pwErr);
      }

      // Save staff profile data locally before signup (include role)
        // Save staff profile data locally before signup (include role)
        print('[staffSignUp] Saving pending staff profile for: $email, role: $role');
        await ProfileStorage.savePendingProfile({
          'email': email.trim().toLowerCase(),
          'username': username.trim(),
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'date_of_birth': dateOfBirth.trim(),
          'contact_no': contactNo.trim(),
          'role': role.trim(), // important for claim step
        });

        // Use Supabase auth signUp (same as member flow)
        print('[staffSignUp] Calling Supabase signUp for: $email');
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        print('[staffSignUp] Supabase signUp response: ${response.user?.id}, response: $response');
        return response;

    } catch (e) {
      print('[staffSignUp] Error checking existing user: $e');
      return Future.error('Error checking existing user: $e');
    }
  }

  // Claim pending profile after authentication
  Future<void> tryClaimPendingProfile({int maxRetries = 3}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[tryClaimPendingProfile] No current user, aborting.');
      return;
    }

    final pending = await ProfileStorage.getPendingProfile();
    if (pending == null) {
      print('[tryClaimPendingProfile] No pending profile found, aborting.');
      return;
    }

    final role = (pending['role'] ?? 'member').toString().toLowerCase();
    print('[tryClaimPendingProfile] Pending profile: $pending, role: $role');

    // Build common row; will adjust per table below
    final row = <String, dynamic>{
      'email_address': pending['email'] ?? user.email,
      'username': pending['username'],
      'first_name': pending['first_name'],
      'last_name': pending['last_name'],
      'contact_no': pending['contact_no'],
      'date_of_birth': pending['date_of_birth'],
    };

    // Remove empty/null date_of_birth to avoid DB errors (calling code may require non-null)
    if (row['date_of_birth'] == null || (row['date_of_birth'] as String).isEmpty) {
      row.remove('date_of_birth');
    }

    // If staff, ensure role present in row (staff table requires role)
    if (role == 'encoder') {
      row['role'] = pending['role'] ?? 'encoder';
    }

    final targetTable = role == 'encoder' ? 'staff' : 'members';
    print('[tryClaimPendingProfile] Target table: $targetTable, row: $row');

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {

        print('[tryClaimPendingProfile] Attempt ${attempt + 1} to insert/update $targetTable for email: ${row['email_address']}');
        // Use checkUserExists to determine if user already exists
        final exists = await checkUserExists(row['email_address'] ?? '');

        if (exists) {
          print('[tryClaimPendingProfile] Existing record found, updating...');
          // Update existing record (by email)
          await _supabase
              .from(targetTable)
              .update(row)
              .eq('email_address', row['email_address']);
          print('[tryClaimPendingProfile] Update successful.');
        } else {
          print('[tryClaimPendingProfile] No existing record, inserting new...');
          // Insert new record
          await _supabase.from(targetTable).insert(row);
          print('[tryClaimPendingProfile] Insert successful.');
        }

        // Success - clear pending profile
        await ProfileStorage.clearPendingProfile();
        print('[tryClaimPendingProfile] Cleared pending profile after successful insert/update.');
        return;

      } catch (e) {
        print('[tryClaimPendingProfile] Error on attempt ${attempt + 1}: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        } else {
          print('[tryClaimPendingProfile] Max retries reached. Not clearing pending profile.');
          // Don't clear pending profile on failure - admin/user can try again later
          return;
        }
      }
    }
  }

  // Check if user exists before registration
  Future<bool> checkUserExists(String email, {String? username}) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedUsername = username?.trim();

    // If both empty, nothing to check
    if ((trimmedEmail.isEmpty) && (trimmedUsername == null || trimmedUsername.isEmpty)) {
      return false;
    }

    try {
      // Debug
      print('checkUserExists: email="$trimmedEmail" username="$trimmedUsername"');

      // Check by email if provided (email match is already normalized)
      if (trimmedEmail.isNotEmpty) {
        final staffByEmail = await _supabase
            .from('staff')
            .select('id')
            .eq('email_address', trimmedEmail)
            .maybeSingle();
        if (staffByEmail != null) {
          print('checkUserExists: found by email in staff');
          return true;
        }

        final memberByEmail = await _supabase
            .from('members')
            .select('id')
            .eq('email_address', trimmedEmail)
            .maybeSingle();
        if (memberByEmail != null) {
          print('checkUserExists: found by email in members');
          return true;
        }
      }

      // Check by username (case-sensitive)
      if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
        // check staff for username matches (case-sensitive)
        final staffByUsername = await _supabase
            .from('staff')
            .select('id, username, email_address')
            .eq('username', trimmedUsername);

        debugPrint('staffByUsername raw: $staffByUsername');

        if (staffByUsername.isNotEmpty) {
          debugPrint('checkUserExists: found by username in staff: $staffByUsername');
          return true;
        }

        // check members for username matches (case-sensitive)
        final memberByUsername = await _supabase
            .from('members')
            .select('id')
            .eq('username', trimmedUsername);
        if (memberByUsername.isNotEmpty) {
          debugPrint('checkUserExists: found by username in members: $memberByUsername');
          return true;
        }
      }

      // Not found
      debugPrint('checkUserExists: not found');
      return false;
    } catch (e) {
      debugPrint('checkUserExists error: $e');
      rethrow;
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}