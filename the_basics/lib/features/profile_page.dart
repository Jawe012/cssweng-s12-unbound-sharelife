import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double nameSize = 40;
  double roleSize = 28;
  double subtitlesize = 28;
  double contentsize = 18;
  double subtitlegap = 40;
  double contentgap = 16;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _loading = true;
  bool _notSignedIn = false;
  String? _profileImageUrl;
  XFile? _pickedImage; // Store picked image for web compatibility

  // profile fields
  String _firstName = '';
  String _lastName = '';
  String _role = '';
  String _username = '';
  String _dob = '';
  String _contactnum = '';
  String _email = '';
  String _recogDate = '';
  String _status = '';
  String _loanStatus = '';

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      _pickedImage = picked;
      if (!kIsWeb) {
        setState(() => _imageFile = File(picked.path));
      }
      // Upload to Supabase storage
      await _uploadProfileImage(picked);
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showMessage('Not logged in');
        return;
      }

      // Upload to Supabase storage bucket 'profile-images'
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Read file as bytes (works on both web and mobile)
      final bytes = await imageFile.readAsBytes();
      
      await Supabase.instance.client.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Update user profile with image URL
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null) {
        // Try updating members table first
        try {
          await Supabase.instance.client
              .from('members')
              .update({'profile_image_url': imageUrl})
              .eq('email_address', email);
        } catch (e) {
          // If not in members, try staff
          await Supabase.instance.client
              .from('staff')
              .update({'profile_image_url': imageUrl})
              .eq('email_address', email);
        }
      }

      setState(() => _profileImageUrl = imageUrl);
      _showMessage('Profile image updated successfully');
    } catch (e) {
      _showMessage('Error uploading image: $e');
      debugPrint('Upload error: $e');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Return user's initials for avatar fallback
  String _getInitials() {
    final fn = _firstName.trim();
    final ln = _lastName.trim();
    final fi = fn.isNotEmpty ? fn[0].toUpperCase() : '';
    final li = ln.isNotEmpty ? ln[0].toUpperCase() : '';
    final initials = (fi + li);
    return initials.isNotEmpty ? initials : 'U';
  }

  Widget _profileHeading(String fname, String lname, String role) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        // For future iterations of this project, change null -> "onTap: _pickImage" to allow changing one's profile picture
        // It is currently disabled to prevent issues with the max storage limits on the Supabase free tier.
        // To enable this feature, ensure that the 'profile-images' storage bucket exists, and set up the necessary policies for authenticated users
          GestureDetector(
            onTap: null, // disabled
            child: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || (!kIsWeb && _imageFile != null)
                ? CircleAvatar(
                    radius: 100,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : FileImage(_imageFile!) as ImageProvider,
                  )
                : CircleAvatar(
                    radius: 100,
                    backgroundColor: const Color(0xFFb8b8b8), // light gray
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fname $lname',
              style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.bold)
            ),
            Text(
              role, 
              style: TextStyle(color: Colors.grey[600], fontSize: roleSize)
            ),
          ],
        ),

      ],
    );
  }


  Widget _personalInfo(String username, String dob, String contactnum, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personal Information",
          style: TextStyle(fontSize: subtitlesize, fontWeight: FontWeight.bold, color: Colors.black)
        ),
        SizedBox(height: subtitlegap),
        Text(
          "Username: $username",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
        Text(
          "Date of Birth: ${(() {
            if (dob.isEmpty) return 'N/A';
            final dt = DateTime.tryParse(dob);
            if (dt != null) {
              final y = dt.year.toString().padLeft(4, '0');
              final m = dt.month.toString().padLeft(2, '0');
              final d = dt.day.toString().padLeft(2, '0');
              return '$y-$m-$d';
            }
            return dob;
          })()}",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
        Text(
          "Contact Info: $contactnum",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
        Text(
          "Email: $email",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
      ]
    );
  }

  Widget _loanInfo(String recogDate, String status, String loanStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Information",
          style: TextStyle(fontSize: subtitlesize, fontWeight: FontWeight.bold, color: Colors.black)
        ),
        SizedBox(height: subtitlegap),
        Text(
          "Recognition Date: $recogDate",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
        Text(
          "Status: $status",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
        Text(
          "Loan Status: $loanStatus",
          style: TextStyle(fontSize: contentsize, color: Colors.black)
        ),
        SizedBox(height: contentgap),
      ]
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _notSignedIn = false;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _notSignedIn = true;
          _loading = false;
        });
        return;
      }

      final userId = user.id;
      _email = user.email ?? '';

      debugPrint('🔍 Loading profile for user_id: $userId, email: $_email');

      Map<String, dynamic>? asMap(dynamic raw) {
        if (raw == null) return null;
        if (raw is Map<String, dynamic>) return raw;
        if (raw is Map) return Map<String, dynamic>.from(raw);
        return null;
      }

      // helper to try multiple possible column names (returns first non-empty value)
      String pick(Map<String, dynamic>? m, List<String> keys) {
        if (m == null) return '';
        for (final k in keys) {
          if (m.containsKey(k) && m[k] != null) return m[k].toString();
        }
        return '';
      }

      // Try staff first by user_id, then by email if not found
      dynamic staffRaw;
      try {
        staffRaw = await supabase.from('staff').select('*').eq('user_id', userId).maybeSingle();
      } catch (e) {
        debugPrint('Staff by user_id query failed: $e');
      }
      debugPrint('staffRaw (after user_id query): $staffRaw');
      var staffResp = asMap(staffRaw);
      if (staffResp == null && _email.isNotEmpty) {
        try {
          staffRaw = await supabase.from('staff').select('*').eq('email_address', _email).maybeSingle();
          staffResp = asMap(staffRaw);
        } catch (e) {
          debugPrint('Staff by email query failed: $e');
        }
      }
      debugPrint('staffRaw (final): $staffRaw');

      if (staffResp != null) {
        setState(() {
          _firstName = pick(staffResp, ['first_name', 'firstname', 'given_name']);
          _lastName = pick(staffResp, ['last_name', 'lastname', 'family_name']);
          _role = pick(staffResp, ['role']) == '' ? 'Staff' : pick(staffResp, ['role']);
          _username = pick(staffResp, ['username', 'user_name', 'user']);
          _contactnum = pick(staffResp, ['contact_number', 'contact_no', 'contact']);
          _dob = pick(staffResp, ['date_of_birth', 'dob']);
          _recogDate = 'N/A';
          _status = 'N/A';
          _loanStatus = 'N/A';
          _profileImageUrl = pick(staffResp, ['profile_image_url']);
        });
        debugPrint('✅ Loaded staff profile: $_firstName $_lastName');
      } else {
        // Try members table by user_id then email
        dynamic memRaw;
        try {
          memRaw = await supabase.from('members').select('*').eq('user_id', userId).maybeSingle();
        } catch (e) {
          debugPrint('Members by user_id query failed: $e');
        }
        debugPrint('membersRaw (after user_id query): $memRaw');
        var memResp = asMap(memRaw);
        if (memResp == null && _email.isNotEmpty) {
          try {
            memRaw = await supabase.from('members').select('*').eq('email_address', _email).maybeSingle();
            memResp = asMap(memRaw);
          } catch (e) {
            debugPrint('Members by email query failed: $e');
          }
        }
        debugPrint('membersRaw (final): $memRaw');

        if (memResp != null) {
          setState(() {
            _firstName = pick(memResp, ['first_name', 'firstname', 'given_name']);
            _lastName = pick(memResp, ['last_name', 'lastname', 'family_name']);
            final r = pick(memResp, ['role']);
            _role = r == '' ? 'Member' : r;
            _username = pick(memResp, ['username', 'user_name', 'user']);
            _contactnum = pick(memResp, ['contact_number', 'contact_no', 'contact']);
            _dob = pick(memResp, ['date_of_birth', 'dob']);
            _recogDate = pick(memResp, ['recognition_date', 'recognitionDate']);
            _status = pick(memResp, ['status']) == '' ? 'active' : pick(memResp, ['status']);
            _profileImageUrl = pick(memResp, ['profile_image_url']);
          });
          debugPrint('✅ Loaded member profile: $_firstName $_lastName');

          // Determine member id column (supporting 'member_id' or 'id')
          dynamic memberIdRaw = memResp['member_id'] ?? memResp['id'] ?? memResp['memberid'] ?? memResp['member_id_int'] ?? memResp['member_id_str'];
          if (memberIdRaw == null) {
            debugPrint('Member id not found on member record; skipping loan status fetch. memResp keys: ${memResp.keys.toList()}');
            setState(() => _loanStatus = 'No loan applications');
          } else {
            // Check both loan_application (pending/rejected) and approved_loans (active) tables
            try {
              debugPrint('Fetching loan status for member_id = $memberIdRaw');
              
              // First check approved_loans for active loans
              final approvedResp = await supabase
                  .from('approved_loans')
                  .select('status')
                  .eq('member_id', memberIdRaw)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();
              
              if (approvedResp != null && approvedResp['status'] != null) {
                setState(() => _loanStatus = 'Active: ${approvedResp['status']}');
              } else {
                // Check loan_application for pending/rejected
                final loanResp = await supabase
                    .from('loan_application')
                    .select('status')
                    .eq('member_id', memberIdRaw)
                    .order('created_at', ascending: false)
                    .limit(1)
                    .maybeSingle();

                debugPrint('loanResp: $loanResp');
                final loanMap = asMap(loanResp);
                if (loanMap != null && loanMap['status'] != null) {
                  setState(() => _loanStatus = loanMap['status'].toString());
                } else {
                  setState(() => _loanStatus = 'No loan applications');
                }
              }
            } catch (e) {
              debugPrint('Error fetching loan status: $e');
              setState(() => _loanStatus = 'No loan applications');
            }
          }
        } else {
          debugPrint('❌ No data found in staff or members tables for user_id/email');
          debugPrint('💡 Check if user_id or email exists in your database tables');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [

          // Top Navbar things
          TopNavBar(splash: "Settings", 
            logoIsBackButton: true, 
            onAccountSettings: () {},
            onLogoBack: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }
          ),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SideMenu(role: "Settings"),

                Expanded(
                  flex: 4, // right area ~80%
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 350.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [ IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Text("Back", style: TextStyle(fontSize: 18, color: Colors.black),),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          if (_loading) ...[
                            const SizedBox(height: 80),
                            const Center(child: CircularProgressIndicator()),
                          ] else if (_notSignedIn) ...[
                            const SizedBox(height: 40),
                            const Text('No user signed in', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              child: const Text('Go to Login'),
                            )
                          ] else ...[
                            _profileHeading(_firstName.isNotEmpty ? _firstName : 'First', _lastName.isNotEmpty ? _lastName : 'Last', _role.isNotEmpty ? _role : 'Member'),
                            SizedBox(height: 80),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _personalInfo(
                                  _username.isNotEmpty ? _username : '${_firstName.isNotEmpty ? _firstName : 'First'} ${_lastName.isNotEmpty ? _lastName : 'Last'}',
                                  _dob.isNotEmpty ? _dob : 'N/A',
                                  _contactnum.isNotEmpty ? _contactnum : 'N/A',
                                  _email.isNotEmpty ? _email : 'no-email',
                                ),
                                SizedBox(width: 80),
                                _loanInfo(_recogDate.isNotEmpty ? _recogDate : 'N/A', _status.isNotEmpty ? _status : 'N/A', _loanStatus.isNotEmpty ? _loanStatus : 'N/A'),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
  }