import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

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


  Widget _personalInfo(String username, String DOB, String contactnum, String email) {
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
          "Date of Birth: $DOB",
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
                          _profileHeading("Mark Anthony", "Garcia", "Member"),
                          SizedBox(height: 80),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _personalInfo("Mark Anthony", "January 1, 1970", "0917 123 4567", "markanthony@email.com"),
                              SizedBox(width: 80),
                              _loanInfo("January 1, 2020", "Active", "Active"),
                            ],
                          )
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