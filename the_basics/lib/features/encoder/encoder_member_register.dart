import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/auth/auth_service.dart';

/// Encoder-specific member registration page for walk-in applicants.
/// Unlike the normal registration flow, this inserts directly into the members table
/// (skipping profile_storage) and then creates the auth account.
class EncoderMemberRegisterPage extends StatefulWidget {
  const EncoderMemberRegisterPage({super.key});

  @override
  State<EncoderMemberRegisterPage> createState() => _EncoderMemberRegisterPageState();
}

class _EncoderMemberRegisterPageState extends State<EncoderMemberRegisterPage> {
  final authService = AuthService();

  // text controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showConfirmPassword = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final shouldShow = _passwordController.text.isNotEmpty;
      if (shouldShow != _showConfirmPassword) {
        setState(() => _showConfirmPassword = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _usernameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Main submission handler: insert member record, then create auth account
  Future<void> _submitMemberRegistration() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final dateOfBirth = _dateOfBirthController.text.trim();
    final contactNo = _contactNumberController.text.trim();

    // INPUT VALIDATION
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        dateOfBirth.isEmpty ||
        contactNo.isEmpty) {
      _showError("Please fill in all fields.");
      setState(() => _isProcessing = false);
      return;
    }

    // Parse and convert date of birth to ISO format (YYYY-MM-DD)
    String dobIso = '';
    if (dateOfBirth.isNotEmpty) {
      try {
        final dobParts = dateOfBirth.split('/');
        if (dobParts.length == 3) {
          final month = int.parse(dobParts[0]);
          final day = int.parse(dobParts[1]);
          final year = int.parse(dobParts[2]);
          final dt = DateTime(year, month, day);
          dobIso = dt.toIso8601String().split('T')[0];
        }
      } catch (_) {
        _showError("Invalid date format. Use MM/DD/YYYY.");
        setState(() => _isProcessing = false);
        return;
      }
    }

    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError("Please enter a valid email address.");
      setState(() => _isProcessing = false);
      return;
    }

    // Check password match
    if (password != confirmPassword) {
      _showError("Passwords don't match.");
      setState(() => _isProcessing = false);
      return;
    }

    // Check if user already exists
    try {
      final userExists = await authService.checkUserExists(email, username: username);
      if (userExists) {
        _showError("User with this email or username already exists.");
        setState(() => _isProcessing = false);
        return;
      }
    } catch (e) {
      debugPrint('Error checking user existence: $e');
    }

    // Step 1: Insert member record directly into the members table
    int? newMemberId;
    try {
      final memberPayload = {
        'email_address': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dobIso,
        'contact_no': contactNo,
        'role': 'member',
      };

      final insertedMember = await Supabase.instance.client
          .from('members')
          .insert(memberPayload)
          .select('id')
          .single();

      newMemberId = insertedMember['id'] is int
          ? insertedMember['id']
          : int.tryParse(insertedMember['id'].toString());

      if (newMemberId == null) {
        throw Exception('Failed to retrieve new member ID after insert.');
      }

      debugPrint('[EncoderMemberRegister] Inserted member id: $newMemberId');
    } catch (e) {
      _showError("Failed to create member record: $e");
      setState(() => _isProcessing = false);
      return;
    }

    // Step 2: Create auth account (sign up) - skip profile storage since member already inserted
    try {
      // Use the low-level supabase auth signUp directly (no profile storage)
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        _showError("Sign up did not complete. Please try again.");
        setState(() => _isProcessing = false);
        return;
      }

      debugPrint('[EncoderMemberRegister] Auth account created for: $email');

      // Success: return the new member ID to the encoder form
      if (!mounted) return;
      Navigator.of(context).pop({
        'member_id': newMemberId,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth, // return original format for UI display
        'email_address': email,
        'contact_no': contactNo,
      });
    } on AuthException catch (authError) {
      _showError("Sign up error: ${authError.message}");
      setState(() => _isProcessing = false);
    } catch (e) {
      _showError("Error: $e");
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Register New Member (Walk-in)'),
        backgroundColor: const Color(0xFF0C0C0D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Two groups side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group 1: Personal Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                              hintText: 'First Name',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                              hintText: 'Last Name',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _dateOfBirthController,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              hintText: 'MM/DD/YYYY',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _contactNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                              hintText: '09XX XXX XXXX',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    // Group 2: Log In Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Log In Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                              hintText: 'Username',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                              hintText: 'Email Address',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              hintText: 'Password',
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Animated fade for Confirm Password
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: _showConfirmPassword
                                ? TextField(
                                    key: const ValueKey('confirm_field'),
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm Password',
                                      border: OutlineInputBorder(),
                                      hintText: 'Confirm Password',
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('confirm_empty'),
                                    height: 0,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Register button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _submitMemberRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C0C0D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Member Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
