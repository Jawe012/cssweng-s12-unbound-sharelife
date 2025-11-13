import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';

import 'dart:io';
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
      setState(() => _imageFile = File(picked.path));
    }
  }

  Widget _profileHeading(String fname, String lname, String role) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 100,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
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
          "Date of Birth: $dob",
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

      _email = user.email ?? '';

      // Try staff first
      final staffResp = await supabase.from('staff').select('first_name,last_name,role,username,contact_no,email_address,date_of_birth').eq('email_address', _email).maybeSingle();
      if (staffResp != null) {
        setState(() {
          _firstName = (staffResp['first_name'] ?? '') as String;
          _lastName = (staffResp['last_name'] ?? '') as String;
          _role = (staffResp['role'] ?? '') as String;
          _username = (staffResp['username'] ?? '') as String;
          _contactnum = (staffResp['contact_no'] ?? '') as String;
          _dob = (staffResp['date_of_birth'] ?? '') as String;
        });
      } else {
        // Try members table
        final memResp = await supabase.from('members').select('first_name,last_name,role,username,contact_no,email_address,date_of_birth,recognition_date,status,loan_status').eq('email_address', _email).maybeSingle();
        if (memResp != null) {
          setState(() {
            _firstName = (memResp['first_name'] ?? '') as String;
            _lastName = (memResp['last_name'] ?? '') as String;
            _role = (memResp['role'] ?? '') as String;
            _username = (memResp['username'] ?? '') as String;
            _contactnum = (memResp['contact_no'] ?? '') as String;
            _dob = (memResp['date_of_birth'] ?? '') as String;
            _recogDate = (memResp['recognition_date'] ?? '') as String;
            _status = (memResp['status'] ?? '') as String;
            _loanStatus = (memResp['loan_status'] ?? '') as String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
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