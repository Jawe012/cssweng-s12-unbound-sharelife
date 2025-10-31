import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoanReviewDetailsPage extends StatefulWidget {
  const LoanReviewDetailsPage({super.key});

  @override
  State<LoanReviewDetailsPage> createState() => _LoanReviewDetailsPageState();
}

class _LoanReviewDetailsPageState extends State<LoanReviewDetailsPage> {
  int loanAmount = 0;
  int annualIncome = 0;
  int age = 0;
  String installment = '';
  String repaymentTerm = '';
  String businessType = '';
  String reason = '';
  String memberFirstName = '';
  String memberLastName = '';
  String memberBirthDate = '';
  String spouseFirstName = '';
  String spouseLastName = '';
  String childFirstName = '';
  String childLastName = '';
  String memberEmail = '';
  String memberPhone = '';
  String address = '';

  bool _isLoading = true;

  String decision = 'Approve';
  String reason1 = 'Missing Documents';
  String reason2 = 'Incomplete Requirements';
  final TextEditingController remarksController = TextEditingController();

  // for spacing
  double titleSpacing = 18;
  double textSpacing = 12;
  double dataSpacing = 100;
  double divSpacing = 100;

  // font sizes
  double titleFont = 20;
  double contentFont = 16;

  //calculate age
  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  //getting loan details
  Future<void> fetchLoanDetails(int id) async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('loan_application')
          .select()
          .eq('application_id', id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          // Loan Info
          loanAmount = response['loan_amount'] ?? 0;
          annualIncome = response['annual_income'] ?? 0;
          installment = response['installment'] ?? '';
          repaymentTerm = response['repayment_term'] ?? '';
          businessType = response['business_type'] ?? '';
          reason = response['reason'] ?? '';

          // Personal Info
          memberFirstName = response['member_first_name'] ?? '';
          memberLastName = response['member_last_name'] ?? '';
          memberBirthDate = response['member_birth_date']?.toString() ?? '';
          if (memberBirthDate.isNotEmpty) {
            age = calculateAge(DateTime.parse(memberBirthDate));
          }

          // Co-makers
          spouseFirstName = response['comaker_spouse_first_name'] ?? '';
          spouseLastName = response['comaker_spouse_last_name'] ?? '';
          childFirstName = response['comaker_child_first_name'] ?? '';
          childLastName = response['comaker_child_last_name'] ?? '';

          // Contact Info
          memberEmail = response['member_email'] ?? '';
          memberPhone = response['member_phone'] ?? '';
          address = response['address'] ?? '';
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading loan details: $e'))
      );
    }
  }

  @override
  @override
  void initState() {
    super.initState();
    // Defer accessing ModalRoute.of(context) until after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loanId = ModalRoute.of(context)?.settings.arguments as int?;
      if (loanId != null) {
        fetchLoanDetails(loanId);
      }
    });
  }

  //changing the status
  Future<void> updateLoanStatus(String status) async {
    try {
      final loanId = ModalRoute.of(context)?.settings.arguments as int?;
      if (loanId == null) {
        throw Exception('No loan ID provided');
      }

      await Supabase.instance.client
          .from('loan_application')
          .update({
            'status': status,
            'admin_remarks': remarksController.text,
            'approved_by': Supabase.instance.client.auth.currentUser?.id,
          })
          .eq('application_id', loanId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Loan $status successfully."))
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e"))
      );
    }
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  Widget loanInfo(double loanAmt, double annualInc, int installments,
                  String repayTerm, String busType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Loan Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Desired Loan Amount: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Annual Income: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Desired Installments: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Repayment Term: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Business Type: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₱$loanAmt', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('₱$annualInc', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$installments', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$repayTerm', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$busType', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget personalInfo(String fName, String lName, String dob, int age) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Borrower First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Borrower Last Name: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Date of Birth: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Age: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$fName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$lName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$dob', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$age', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget loanCoMakers(String spouseFName, String spouseLName,
                      String childFName, String childLName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Loan Co-makers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Spouse First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Spouse Last Name: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Children First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Children Last Name: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$spouseFName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$spouseLName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$childFName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$childLName', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget contactInfo(String email, String phone, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Contact Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Phone Number: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Home Address: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$email', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$phone', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$address', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget decisionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text("Decision",
                style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: titleFont
              )),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Text("Decision:  "),
            SizedBox(width: titleSpacing),
            DropdownButton<String>(
              value: decision,
              items: [
                DropdownMenuItem(
                    value: "Approve",
                    child: Text("Approve")),
                DropdownMenuItem(
                    value: "Reject",
                    child: Text("Reject")),
              ],
              onChanged: (value) {
                setState(() {
                  decision = value!;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12),
        TextField(
          controller: remarksController,
          decoration: InputDecoration(
            labelText: "Remarks (optional)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Applicant will be notified via email upon approval or rejection.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buttonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => updateLoanStatus('Approved'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Approve",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => updateLoanStatus('Rejected'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Reject",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ...existing title and back button...
                              
                              // Updated GridView with state variables
                              GridView(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 30,
                                  mainAxisSpacing: 30,
                                  mainAxisExtent: 230,
                                ),
                                children: [
                                  loanInfo(loanAmount.toDouble(), annualIncome.toDouble(), 
                                         int.tryParse(installment) ?? 0, repaymentTerm, businessType),
                                  personalInfo(memberFirstName, memberLastName, memberBirthDate, age),
                                  loanCoMakers(spouseFirstName, spouseLastName, childFirstName, childLastName),
                                  contactInfo(memberEmail, memberPhone, address),
                                ],
                              ),
                              Divider(),
                              decisionSection(),
                              buttonsRow(),
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