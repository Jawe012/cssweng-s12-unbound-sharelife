import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/input_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/features/encoder/encoder_member_register.dart';

class EncAppliform extends StatefulWidget {
  const EncAppliform({super.key});

  @override
  State<EncAppliform> createState() => _EncAppliformState();
}

class _EncAppliformState extends State<EncAppliform> {

  final TextEditingController appliDateController = TextEditingController();
  
  // loan info
  final TextEditingController loanAmtController = TextEditingController();
  final TextEditingController anlIncController = TextEditingController();
  final TextEditingController instController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  final TextEditingController businessController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  
  // personal info
  final TextEditingController fNameController = TextEditingController();
  final TextEditingController lNameController = TextEditingController();
  final TextEditingController bDateController = TextEditingController();
  
  // loan co-maker
  final TextEditingController spouseFNameController = TextEditingController();
  final TextEditingController spouseLNameController = TextEditingController();
  final TextEditingController childFNameController = TextEditingController();
  final TextEditingController childLNameController = TextEditingController();
  
  // contact info
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();
  final TextEditingController addrController = TextEditingController();
  bool agreeTerms = false;

  // member search controllers / state
  final TextEditingController searchEmailController = TextEditingController();
  final TextEditingController searchFNameController = TextEditingController();
  final TextEditingController searchLNameController = TextEditingController();
  final TextEditingController searchBDateController = TextEditingController();
  int? selectedMemberId;
  String? selectedMemberName;
  String? staffSearchError;


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        SizedBox(
          height: 28,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download,
                color: Colors.white),
            label: const Text(
              "Download",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(100, 28),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ]
    );
  }

  Widget memberSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Member Lookup",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Email search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Member Email (search)",
                controller: searchEmailController,
                hint: "e.g. member@example.com",
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _onSearchByEmail, child: const Text('Search')),
          ],
        ),

        // small subtext to show staff-related error
        if (staffSearchError != null) ...[
          const SizedBox(height: 6),
          Text(
            staffSearchError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],

        const SizedBox(height: 12),

        // Name + DOB search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "First Name",
                controller: searchFNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextInputField(
                label: "Last Name",
                controller: searchLNameController,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: DateInputField(
                label: "Birth Date (search)",
                controller: searchBDateController,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _onSearchByNameDob, child: const Text('Search')),
          ],
        ),

        const SizedBox(height: 12),

        if (selectedMemberId != null) ...[
          Row(
            children: [
              Expanded(child: Text('Selected member: ${selectedMemberName ?? "ID#${selectedMemberId!}"}')),
              TextButton(onPressed: () { setState(() { selectedMemberId = null; selectedMemberName = null; phoneNumController.text = ''; }); }, child: const Text('Clear')),
            ],
          ),
        ],

        const Divider(),
      ],
    );
  }

  // --- Member search helpers
  Future<Map<String, dynamic>?> _findMemberByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final rec = await Supabase.instance.client
          .from('members')
          .select('id, first_name, last_name, date_of_birth, email_address, contact_no')
          .eq('email_address', email.trim().toLowerCase())
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching member by email: $e');
      return null;
    }
  }

  Future<void> _onSearchByEmail() async {
    final email = searchEmailController.text.trim().toLowerCase();
    setState(() { staffSearchError = null; });
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an email to search.')));
      return;
    }

    // Check staff table specifically — staff cannot have loans
    try {
      final staffRec = await Supabase.instance.client.from('staff').select('id').eq('email_address', email).maybeSingle();
      if (staffRec != null) {
        setState(() {
          staffSearchError = 'This email belongs to a staff account — staff cannot have loans.';
        });
        return;
      }
    } catch (e) {
      debugPrint('Error checking staff table: $e');
    }

    // Not staff — try to find member
    final rec = await _findMemberByEmail(email);
    if (rec != null) {
      await _showFoundMemberDialog(rec);
    } else {
      final create = await _showNotFoundDialog();
      if (create == true) await _navigateToCreateMember();
    }
  }

  Future<Map<String, dynamic>?> _findMemberByNameDob(String first, String last, String dobText) async {
    if (first.trim().isEmpty || last.trim().isEmpty || dobText.trim().isEmpty) return null;
    try {
      String iso = dobText;
      try {
        final parts = dobText.split('/');
        if (parts.length == 3) {
          final m = int.parse(parts[0]);
          final d = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          iso = DateTime(y, m, d).toIso8601String().split('T').first;
        }
      } catch (_) {}

      final rec = await Supabase.instance.client
          .from('members')
          .select('id, first_name, last_name, date_of_birth, email_address, contact_no')
          .eq('first_name', first.trim())
          .eq('last_name', last.trim())
          .eq('date_of_birth', iso)
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching member by name/dob: $e');
      return null;
    }
  }

  Future<void> _onSearchByNameDob() async {
    final first = searchFNameController.text.trim();
    final last = searchLNameController.text.trim();
    final dob = searchBDateController.text.trim();
    if (first.isEmpty || last.isEmpty || dob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide first name, last name and birth date to search.')));
      return;
    }
    final rec = await _findMemberByNameDob(first, last, dob);
    if (rec != null) {
      await _showFoundMemberDialog(rec);
    } else {
      final create = await _showNotFoundDialog();
      if (create == true) await _navigateToCreateMember();
    }
  }

  Future<void> _showFoundMemberDialog(Map<String, dynamic> rec) async {
    final id = rec['id'];
    final fname = rec['first_name'] ?? '';
    final lname = rec['last_name'] ?? '';
    final email = rec['email_address'] ?? '';
    final contact = rec['contact_no'] ?? '';
    final dobRaw = rec['date_of_birth'];
    String dobPretty = '';
    try {
      if (dobRaw != null) {
        final dt = DateTime.parse(dobRaw.toString());
        dobPretty = "${dt.month}/${dt.day}/${dt.year}";
      }
    } catch (_) {}

    final use = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Existing member found'),
        content: Text('Existing member: $fname $lname — ID#${id}\n$email\nPhone: $contact\nDOB: $dobPretty\n\nUse this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Create new')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Use this')),
        ],
      ),
    );

    if (use == true) {
      setState(() {
        selectedMemberId = id is int ? id : int.tryParse(id.toString());
        selectedMemberName = '$fname $lname';
        // autofill fields including contact number
        fNameController.text = fname;
        lNameController.text = lname;
        if (dobPretty.isNotEmpty) bDateController.text = dobPretty;
        emailController.text = email;
        phoneNumController.text = contact;
      });
    }
  }

  Future<bool?> _showNotFoundDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Member not found'),
        content: const Text('No existing member found. Would you like to create a new member account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create new'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateMember() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const EncoderMemberRegisterPage()),
    );

    if (result != null && result['member_id'] != null) {
      // autofill fields
      setState(() {
        selectedMemberId = result['member_id'];
        selectedMemberName = '${result['first_name']} ${result['last_name']}';
        fNameController.text = result['first_name'] ?? '';
        lNameController.text = result['last_name'] ?? '';
        bDateController.text = result['date_of_birth'] ?? '';
        emailController.text = result['email_address'] ?? '';
        phoneNumController.text = result['contact_no'] ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member "${selectedMemberName}" created and selected.')),
      );
    }
  }

  // submit handler: insert into temporary_loan_information
  Future<void> submitForm() async {
    // require selected member
    if (selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or create a member before submitting an application.')));
      return;
    }

    // get current signed-in user's email to resolve staff id
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (currentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to determine current user. Please sign in as staff.')));
      return;
    }

    int? staffId;
    try {
      final staffRec = await Supabase.instance.client.from('staff').select('id').eq('email_address', currentEmail).maybeSingle();
      if (staffRec != null && staffRec['id'] != null) {
        staffId = staffRec['id'] is int ? staffRec['id'] : int.tryParse(staffRec['id'].toString());
      }
    } catch (e) {
      debugPrint('Error resolving staff id: $e');
    }

    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to resolve staff id for current user. Ensure you are signed in as staff.')));
      return;
    }

    // convert birthdate to ISO (YYYY-MM-DD) for DB date field
    String dobIso = '';
    final bDate = bDateController.text.trim();
    if (bDate.isNotEmpty) {
      try {
        final parts = bDate.split('/');
        if (parts.length == 3) {
          final m = int.parse(parts[0]);
          final d = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          dobIso = DateTime(y, m, d).toIso8601String().split('T').first;
        }
      } catch (_) {}
    }

    final payload = {
      'member_id': selectedMemberId,
      'installment': instController.text,
      'repayment_term': termController.text,
      'loan_amount': int.tryParse(loanAmtController.text) ?? 0,
      'annual_income': int.tryParse(anlIncController.text) ?? 0,
      'business_type': businessController.text,
      'reason': reasonController.text,
      'member_first_name': fNameController.text,
      'member_last_name': lNameController.text,
      'member_birth_date': dobIso,
      'member_email': emailController.text,
      'member_phone': phoneNumController.text,
      'address': addrController.text,
      'consent': agreeTerms,
      'comaker_spouse_first_name': spouseFNameController.text,
      'comaker_spouse_last_name': spouseLNameController.text,
      'comaker_child_first_name': childFNameController.text,
      'comaker_child_last_name': childLNameController.text,
    };

    try {
      await Supabase.instance.client.from('loan_application').insert(payload);

      // clear page after submission
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Loan Application Submitted'),
          content: const Text('The application has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EncAppliform()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit application: $e')));
    }
  }

  Widget appliDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [ 
        Text(
          "Date of Application",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 250,
          child: DateInputField(
              label: "Date of Application",
              controller: appliDateController,
          ),
        ),
      ],
    );
  }

  Widget loanInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
                child: NumberInputField(
                label: "Desired Loan Amount",
                controller: loanAmtController,
                hint: "₱0"
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: NumberInputField(
                label: "Annual Income",
                controller: anlIncController,
                hint: "₱0"
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: DropdownInputField(
                label: "Desired Installments",
                controller: instController,
                items: [
                  "3 months",
                  "6 months",
                  "12 months",
                  "24 months",
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownInputField(
                label: "Repayment Term",
                controller: termController,
                items: [
                  "Monthly",
                  "Quarterly",
                  "Semi-Annually",
                  "Annually",
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: DropdownInputField(
                label: "Business Type",
                controller: businessController,
                items: [
                  "Sole Proprietorship",
                  "Partnership",
                  "Corporation",
                  "Cooperative",
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
              label: "Reason", 
              controller: reasonController
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget personalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
      "Personal Information",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 16),

    Row(
      children: [
        Expanded(
          child: TextInputField(
            label: "First Name/s",
            controller: fNameController,
            hint: "e.g. Mark Anthony",
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            label: "Last Name",
            controller: lNameController,
            hint: "e.g. Garcia",
          ),
        ),
      ],
    ),
    SizedBox(height: 16),
    SizedBox(
      width: 250,
      child: DateInputField(
        label: "Birth Date",
        controller: bDateController,
      ),
    ),
      ],
    );
  }

  Widget coMakers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Co-maker",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Spouse First Name/s",
                controller: spouseFNameController,
                hint: "e.g. Maricel Ariel",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Spouse Last Name",
                controller: spouseLNameController,
                hint: "e.g. Garcia",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Child First Name/s",
                controller: childFNameController,
                hint: "e.g. Maricel Ariel",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Child Last Name",
                controller: childLNameController,
                hint: "e.g. Garcia",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget contactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Email",
                controller: emailController,
                hint: "e.g. markanthony@email.com",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Phone Number",
                controller: phoneNumController,
                hint: "+63 912 345 6789",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextInputField(
                label: "Home Address",
                controller: addrController,
                hint: "e.g. Malate, Manila, Philippines",
        ),
      ],
    );
  }

  Widget consentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Consent",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          "I authorize prospective Credit Grantors/Lending/Leasing Companies to obtain personal and credit information about me from my employer and credit bureau, or credit reporting agency, any person who has or may have any financial dealing with me, or from any references I have provided. This information, as well as that provided by me in the application, will be referred to in connection with this lease and any other relationships we may establish from time to time. Any personal and credit information obtained may be disclosed from time to time to other lenders, credit bureaus or other credit reporting agencies.",
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        CheckboxListTile(
          title: Text(
            "I hereby agree that the information given is true, accurate and complete as of the date of this application submission.",
            style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          value: agreeTerms,
          onChanged: (value) {
            setState(() {
              agreeTerms = value!;
            });
          },
          activeColor: Colors.black,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Encoder"),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Encoder"),

                // main content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          const Text(
                            "Loan Applications",
                            style: TextStyle(fontSize: 28, 
                            fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Apply for a loan.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),

                        // classes for form fields
                          // download button
                          buttonsRow(),

                          // application form
                          Expanded( 
                            child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            // form content
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Member Search
                                  memberSearchSection(),
                                  SizedBox(height: 12),

                                  // Date of Application
                                  appliDate(),                                    
                                  SizedBox(height: 40),

                                  // Loan Information
                                  loanInfo(),
                                  SizedBox(height: 40),
                                  
                                  // Personal Information
                                  personalInfo(),
                                  SizedBox(height: 40),

                                  // Loan Co-maker
                                  coMakers(),
                                  SizedBox(height: 40),

                                  // Contact Information
                                  contactInfo(),
                                  SizedBox(height: 40),

                                  // Consent
                                  consentForm(),
                                  SizedBox(height: 18),


                                  // Submit button
                                  Center( 
                                    child: ElevatedButton.icon(
                                      onPressed: submitForm,
                                      
                                      label: const Text(
                                        "Submit Application",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                        backgroundColor: Colors.black,
                                        minimumSize: const Size(100, 28),
                                      ),
                                    ),
                                  )

                                ],
                              ),
                            ),


                            ),
                          ),


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