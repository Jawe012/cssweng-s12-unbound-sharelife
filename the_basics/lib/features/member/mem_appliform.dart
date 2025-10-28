import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoanApplication {
  final int memberId;
  final int amount;
  final String installment;
  final String repaymentTerm;
  final int? loanAmount;
  final int? annualIncome;
  final String? repaymentFrequency;
  final String? memberFirstName;
  final String? memberLastName;
  final String? memberBirthDate;
  final String? spouseFirstName;
  final String? spouseLastName;
  final String? childFirstName;
  final String? childLastName;
  final String? memberEmail;
  final String? memberPhone;
  final String? address;
  final bool consent;

  LoanApplication({
    required this.memberId,
    required this.amount,
    required this.installment,
    required this.repaymentTerm,
    this.loanAmount,
    this.annualIncome,
    this.repaymentFrequency,
    this.memberFirstName,
    this.memberLastName,
    this.memberBirthDate,
    this.spouseFirstName,
    this.spouseLastName,
    this.childFirstName,
    this.childLastName,
    this.memberEmail,
    this.memberPhone,
    this.address,
    required this.consent,
  });

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'amount': amount,
      'installment': installment,
      'repayment_term': repaymentTerm,
      'loan_amount': loanAmount,
      'annual_income': annualIncome,
      'repayment_frequency': repaymentFrequency,
      'member_first_name': memberFirstName,
      'member_last_name': memberLastName,
      'member_birth_date': memberBirthDate,
      'comaker_spouse_first_name': spouseFirstName,
      'comaker_spouse_last_name': spouseLastName,
      'comaker_child_first_name': childFirstName,
      'comaker_child_last_name': childLastName,
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

  final TextEditingController appliDateController = TextEditingController();
  
  // loan info
  final TextEditingController loanAmtController = TextEditingController();
  final TextEditingController anlIncController = TextEditingController();
  final TextEditingController instController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  
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

  Future<void> submitForm() async {
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

  // Basic validation for required fields
  if (loanAmtController.text.isEmpty || emailController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fill in all required fields."))
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
      .select('id')
      .eq('email_address', email)
      .maybeSingle();

  if (memberRecord == null || memberRecord['id'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Member record not found."))
    );
    return;
  }

  Future<void> submitToSupabase(LoanApplication application) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('loan_application')
        .insert(application.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Application submitted successfully!"))
    );
  } catch (e) {
    print("Submission error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to submit application. Please try again."))
    );
  }
  }

  final application = LoanApplication(
    memberId: memberRecord['id'],
    amount: int.tryParse(loanAmtController.text) ?? 0,
    installment: instController.text,
    repaymentTerm: termController.text,
    loanAmount: int.tryParse(loanAmtController.text),
    annualIncome: int.tryParse(anlIncController.text),
    repaymentFrequency: null, // Optional: add if you have a field
    memberFirstName: fNameController.text,
    memberLastName: lNameController.text,
    memberBirthDate: bDateController.text,
    spouseFirstName: spouseFNameController.text,
    spouseLastName: spouseLNameController.text,
    childFirstName: childFNameController.text,
    childLastName: childLNameController.text,
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


class TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const TextInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = "",
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class NumberInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const NumberInputField({
    super.key, 
    required this.label, 
    required this.controller, 
    required this.hint
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class DropdownInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> items;

  const DropdownInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (value) {
        controller.text = value!;
      },
    );
  }
}

class DateInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const DateInputField({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          controller.text = "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
        }
      },
    );
  }
}