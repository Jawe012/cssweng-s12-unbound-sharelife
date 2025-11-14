import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoanApplication {
  final int memberId;
  //loan information
  final int loanAmount;
  final int? annualIncome;
  final String? installment;
  final String? repaymentTerm;
  final String? businessType;
  final String? reason;

  //member personal info
  final String? memberFirstName;
  final String? memberLastName;
  final String? memberBirthDate;

  //comaker info
  final String? spouseFirstName;
  final String? spouseLastName;
  final String? childFirstName;
  final String? childLastName;
  final String? groupName;

  //contact info
  final String? memberEmail;
  final String? memberPhone;
  final String? address;
  final bool consent;

  LoanApplication({
    required this.memberId,
    required this.loanAmount,
    required this.installment,
    required this.repaymentTerm,
    this.annualIncome,
    this.businessType,
    this.reason,
    this.memberFirstName,
    this.memberLastName,
    this.memberBirthDate,
    this.spouseFirstName,
    this.spouseLastName,
    this.childFirstName,
    this.childLastName,
    this.groupName,
    this.memberEmail,
    this.memberPhone,
    this.address,
    required this.consent,
  });

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'installment': installment,
      'repayment_term': repaymentTerm,
      'loan_amount': loanAmount,
      'annual_income': annualIncome,
      'business_type': businessType,
      'reason': reason,
      'member_first_name': memberFirstName,
      'member_last_name': memberLastName,
      'member_birth_date': memberBirthDate,
      'comaker_spouse_first_name': spouseFirstName,
      'comaker_spouse_last_name': spouseLastName,
      'comaker_child_first_name': childFirstName,
      'comaker_child_last_name': childLastName,
      'comaker_group_name': groupName,
      'member_email': memberEmail,
      'member_phone': memberPhone,
      'address': address,
      'consent': consent,
    };
  }
}

class MemAppliform extends StatefulWidget {
  const MemAppliform({super.key});

  @override
  State<MemAppliform> createState() => _MemAppliformState();
}

class _MemAppliformState extends State<MemAppliform> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  final TextEditingController appliDateController = TextEditingController();
  
  // loan info
  final TextEditingController loanAmtController = TextEditingController();
  final TextEditingController anlIncController = TextEditingController();
  final TextEditingController instController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  
  // personal info
  final TextEditingController fNameController = TextEditingController();
  final TextEditingController lNameController = TextEditingController();
  final TextEditingController bDateController = TextEditingController();
  
  // loan co-maker (OPTIONAL - nullable in schema)
  final TextEditingController spouseFNameController = TextEditingController();
  final TextEditingController spouseLNameController = TextEditingController();
  final TextEditingController childFNameController = TextEditingController();
  final TextEditingController childLNameController = TextEditingController();
  final TextEditingController groupController = TextEditingController();
  
  // contact info
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();
  final TextEditingController addrController = TextEditingController();
  bool agreeTerms = false;

  Future<void> submitForm() async {
  // Validate form fields first
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fill in all required fields."))
    );
    return;
  }

  // Validate consent
  if (!agreeTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You must agree to the terms before submitting."))
    );
    return;
  }

  //Check if user is logged in
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You must be logged in to submit an application."))
    );
    return;
  }

  final email = user.email;

  //Check if user is a member
  if(email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User email not found."))
    );
    return;
  }

  final memberRecord = await Supabase.instance.client
      .from('members')
      .select('id, first_name, last_name, date_of_birth')
      .eq('email_address', email.trim().toLowerCase())
      .maybeSingle();

  if (memberRecord == null || memberRecord['id'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Member record not found."))
    );
    return;
  }

  if (memberRecord['date_of_birth'] == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Birth date missing in member record."))
  );
  return;
  }

  // Parse database birth date
  final DateTime dbBirthDate = DateTime.parse(memberRecord['date_of_birth']);
  
  // Normalize values for comparison (trim whitespace)
  final dbFirstName = (memberRecord['first_name'] ?? '').toString().trim();
  final dbLastName = (memberRecord['last_name'] ?? '').toString().trim();
  final inputFirstName = fNameController.text.trim();
  final inputLastName = lNameController.text.trim();
  final inputBirthDateText = bDateController.text.trim();

  // Parse input birth date - handle both MM-DD-YYYY and M/D/Y formats
  DateTime? inputBirthDate;
  try {
    // Try parsing MM-DD-YYYY or M-D-Y format (with dashes)
    final dashParts = inputBirthDateText.split('-');
    if (dashParts.length == 3) {
      final m = int.parse(dashParts[0]);
      final d = int.parse(dashParts[1]);
      final y = int.parse(dashParts[2]);
      inputBirthDate = DateTime(y, m, d);
    } else {
      // Try parsing M/D/Y format (with slashes)
      final slashParts = inputBirthDateText.split('/');
      if (slashParts.length == 3) {
        final m = int.parse(slashParts[0]);
        final d = int.parse(slashParts[1]);
        final y = int.parse(slashParts[2]);
        inputBirthDate = DateTime(y, m, d);
      }
    }
  } catch (e) {
    print('Error parsing birth date: $e');
  }

  if (inputBirthDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid birth date format. Please enter a valid date."))
    );
    return;
  }

  // Compare dates by year, month, day
  if(dbFirstName != inputFirstName ||
     dbLastName != inputLastName || 
     dbBirthDate.year != inputBirthDate.year ||
     dbBirthDate.month != inputBirthDate.month ||
     dbBirthDate.day != inputBirthDate.day) {
    final formattedDbBirthDate = "${dbBirthDate.month}/${dbBirthDate.day}/${dbBirthDate.year}";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Provided name does not match member records.\nExpected: $dbFirstName $dbLastName (DOB: $formattedDbBirthDate)"))
    );
    return;
  }

  Future<void> submitToSupabase(LoanApplication application) async {
  final supabase = Supabase.instance.client;

  try {
    await supabase
        .from('loan_application')
        .insert(application.toJson());

    // Show confirmation dialog, then refresh the page by replacing route with a new instance
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
    // Replace current route with a fresh instance of the form to clear everything
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MemAppliform()));
  } catch (e) {
    print("Submission error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to submit application. Please try again."))
    );
  }
  }

  final application = LoanApplication(
    memberId: memberRecord['id'],
    loanAmount: int.tryParse(loanAmtController.text) ?? 0,
    installment: instController.text,
    repaymentTerm: termController.text,
    annualIncome: int.tryParse(anlIncController.text),
    businessType: businessTypeController.text,
    reason: reasonController.text,
    memberFirstName: fNameController.text,
    memberLastName: lNameController.text,
    memberBirthDate: bDateController.text,
    spouseFirstName: spouseFNameController.text,
    spouseLastName: spouseLNameController.text,
    childFirstName: childFNameController.text,
    childLastName: childLNameController.text,
    groupName: groupController.text,
    memberEmail: emailController.text,
    memberPhone: phoneNumController.text,
    address: addrController.text,
    consent: agreeTerms,
  );

  await submitToSupabase(application);
  }


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        ExportDropdownButton(
          height: 28,
          minWidth: 100,
          onExportPdf: () async {
            // Export current loan application as PDF
            final appData = {
              'member_first_name': fNameController.text,
              'member_last_name': lNameController.text,
              'member_birth_date': bDateController.text,
              'member_email': emailController.text,
              'member_phone': phoneNumController.text,
              'address': addrController.text,
              'loan_amount': loanAmtController.text,
              'annual_income': anlIncController.text,
              'business_type': businessTypeController.text,
              'installment': instController.text,
              'repayment_term': termController.text,
              'reason': reasonController.text,
              'comaker_spouse_first_name': spouseFNameController.text,
              'comaker_spouse_last_name': spouseLNameController.text,
              'comaker_child_first_name': childFNameController.text,
              'comaker_child_last_name': childLNameController.text,
              'created_at': appliDateController.text,
            };
            final bytes = await ExportService.buildLoanApplicationPdf(appData);
            final result = await ExportService.sharePdf(bytes, filename: 'loan_application.pdf');
            if (result.contains('/') || result.contains('\\')) {
              ExportService.showExportMessage(context, 'Loan application PDF saved to: $result');
            } else {
              ExportService.showExportMessage(context, 'Loan application exported as PDF');
            }
          },
          onExportXlsx: () async {
            // Export as table format
            final appData = [{
              'Field': 'Name',
              'Value': '${fNameController.text} ${lNameController.text}',
            }, {
              'Field': 'Date of Birth',
              'Value': bDateController.text,
            }, {
              'Field': 'Email',
              'Value': emailController.text,
            }, {
              'Field': 'Phone',
              'Value': phoneNumController.text,
            }, {
              'Field': 'Address',
              'Value': addrController.text,
            }, {
              'Field': 'Loan Amount',
              'Value': loanAmtController.text,
            }, {
              'Field': 'Annual Income',
              'Value': anlIncController.text,
            }, {
              'Field': 'Business Type',
              'Value': businessTypeController.text,
            }, {
              'Field': 'Installment',
              'Value': instController.text,
            }, {
              'Field': 'Repayment Term',
              'Value': termController.text,
            }, {
              'Field': 'Reason',
              'Value': reasonController.text,
            }];
            await ExportService.exportAndShareExcel(
              context: context,
              rows: appData,
              filename: 'loan_application.xlsx',
              sheetName: 'Loan Application',
            );
          },
        ),
      ]
    );
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
                hint: "Php 0",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: NumberInputField(
                label: "Annual Income",
                controller: anlIncController,
                hint: "Php 0",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
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
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownInputField(
                label: "Repayment Term",
                controller: termController,
                items: [
                  "Monthly",
                  "Bimonthly",
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Business Type",
                controller: businessTypeController,
                hint: "e.g. Retail, Sari-sari store, etc.",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
              label: "Reason", 
              controller: reasonController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            label: "Last Name",
            controller: lNameController,
            hint: "e.g. Garcia",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
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
        SizedBox(height: 16),
        SizedBox(
          width: 250,
          child: TextInputField(
            label: "Group Name",
            controller: groupController,
          ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  // Basic email validation
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Phone Number",
                controller: phoneNumController,
                hint: "+63 912 345 6789",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextInputField(
                label: "Home Address",
                controller: addrController,
                hint: "e.g. Malate, Manila, Philippines",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
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
          const TopNavBar(splash: "Member"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Member"),

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
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
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