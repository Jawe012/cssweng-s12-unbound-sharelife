import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminEditStaff extends StatefulWidget {
  const AdminEditStaff({super.key});

  @override
  State<AdminEditStaff> createState() => _AdminEditStaffState();
}

class _AdminEditStaffState extends State<AdminEditStaff> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  XFile? profilePicture;
  bool isLoading = false;
  bool isSaving = false;
  int? staffId;
  String _role = '';
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        staffId = args;
        _loadStaffDetails(staffId!);
      } else if (args is Map && args['id'] != null) {
        staffId = args['id'];
        _loadStaffDetails(staffId!);
      }
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffDetails(int id) async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('staff')
          .select('first_name, last_name, date_of_birth, email_address, phone_number, home_address, role')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          firstNameController.text = response['first_name'] ?? '';
          lastNameController.text = response['last_name'] ?? '';
          dobController.text = response['date_of_birth'] ?? '';
          emailController.text = response['email_address'] ?? '';
          phoneController.text = response['phone_number'] ?? '';
          addressController.text = response['home_address'] ?? '';
          _role = (response['role'] ?? '').toString();
          _roleLoaded = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading staff details: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          profilePicture = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _saveStaffDetails() async {
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No staff member selected')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      
      final updates = {
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'date_of_birth': dobController.text.trim(),
        'email_address': emailController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'home_address': addressController.text.trim(),
      };

      await supabase
          .from('staff')
          .update(updates)
          .eq('id', staffId!);

      // TODO: Upload profile picture if selected

      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staff details updated successfully'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);

    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving staff details: $e')),
      );
    }
  }

  Future<void> _toggleRevoke() async {
    if (staffId == null) return;
    setState(() => isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final newRole = (_role.toLowerCase() == 'revoked') ? 'encoder' : 'revoked';

      await supabase
          .from('staff')
          .update({'role': newRole})
          .eq('id', staffId!);

      setState(() {
        _role = newRole;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newRole == 'revoked' ? 'Staff role revoked' : 'Staff role restored'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Column(
        children: [
          TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Staff Details",
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Staff Information",
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // Main Content Card
                            Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        // Insert Pictures
                                        InkWell(
                                          onTap: _pickImage,
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_circle_outline, size: 24),
                                              SizedBox(width: 8),
                                              Text(
                                                "Insert Pictures",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              if (profilePicture != null) ...[
                                                SizedBox(width: 8),
                                                Text(
                                                  "(${profilePicture!.name})",
                                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 32),

                                        // Personal Information Section
                                        Text(
                                          "Personal Information",
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 16),

                                        // First Name and Last Name Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextInputField(
                                                label: "First Name/s",
                                                controller: firstNameController,
                                                hint: "e.g. Mark Anthony",
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: TextInputField(
                                                label: "Last Name",
                                                controller: lastNameController,
                                                hint: "e.g. Mark Anthony",
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),

                                        // Date of Birth
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextInputField(
                                            label: "Date of Birth",
                                            controller: dobController,
                                            hint: "e.g. Mark Anthony",
                                          ),
                                        ),
                                        SizedBox(height: 32),

                                        // Contact Information Section
                                        Text(
                                          "Contact Information",
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 16),

                                        // Email and Phone Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextInputField(
                                                label: "Email",
                                                controller: emailController,
                                                hint: "e.g. Mark Anthony",
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: TextInputField(
                                                label: "Phone",
                                                controller: phoneController,
                                                hint: "e.g. Mark Anthony",
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),

                                        // Home Address
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextInputField(
                                            label: "Home Address",
                                            controller: addressController,
                                            hint: "e.g. Mark Anthony",
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            
                            SizedBox(height: 24),

                            // Confirm Edits Button
                            Center(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : _saveStaffDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isSaving
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Confirm Edits",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Revoke / Restore Role Button (wait for role to load before deciding label)
                            Center(
                              child: ElevatedButton(
                                onPressed: (isSaving || isLoading || !_roleLoaded) ? null : _toggleRevoke,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_roleLoaded
                                      ? Colors.grey
                                      : (_role.toLowerCase() == 'revoked' ? Colors.green : Colors.red),
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isSaving
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : (!_roleLoaded
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                            child: Text(
                                              'Loading...',
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                          )
                                        : Text(
                                            _role.toLowerCase() == 'revoked' ? 'Restore' : 'Revoke',
                                            style: TextStyle(color: Colors.white, fontSize: 16),
                                          )),
                              ),
                            ),
                          ],
                        ),
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