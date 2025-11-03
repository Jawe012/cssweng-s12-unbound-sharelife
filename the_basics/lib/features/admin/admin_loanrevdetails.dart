import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  String? decision; // null means no decision selected yet
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
      // Fetch from loan_application table
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
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan application not found'))
        );
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
      final args = ModalRoute.of(context)?.settings.arguments;
      int? loanId;

      // Debug log the raw args for troubleshooting
      print('[LoanDetails] route args: $args (${args.runtimeType})');

      // Accept either an int id or a Map (loan) with application_id
      if (args is int) {
        loanId = args;
      } else if (args is Map) {
        // Try several common key names for id
        final candidate = args['application_id'] ?? args['id'] ?? args['applicationId'] ?? args['loan_id'];
        print('[LoanDetails] candidate id value: $candidate (${candidate.runtimeType})');
        loanId = _parseIntCandidate(candidate);
      }

      if (loanId != null) {
        print('[LoanDetails] resolved loanId: $loanId');
        fetchLoanDetails(loanId);
      } else {
        // No valid id provided — stop loading and show a friendly message
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No application id provided to details page')),
        );
      }
    });
  }

  //changing the status
  Future<void> updateLoanStatus(String status) async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      int? loanId;
      if (args is int) loanId = args;
      else if (args is Map) {
        final candidate = args['application_id'] ?? args['id'] ?? args['applicationId'] ?? args['loan_id'];
        loanId = _parseIntCandidate(candidate);
      }

      if (loanId == null) throw Exception('No loan ID provided');

      // Get current staff ID for reviewed_by/approved_by
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('No authenticated user');
      
      // Fetch staff ID from staff table using email
      final staffRecord = await Supabase.instance.client
          .from('staff')
          .select('id')
          .eq('email_address', currentUser.email!)
          .maybeSingle();
      
      if (staffRecord == null) throw Exception('Staff record not found');
      final staffId = staffRecord['id'] as int;

        if (status == 'Approved') {
          // APPROVAL FLOW
          // 1. Fetch the full loan record from loan_application
          final loanRecord = await Supabase.instance.client
              .from('loan_application')
              .select()
              .eq('application_id', loanId)
              .single();

          // 1a. Mark original loan_application as Accepted so the edge function can read it
          await Supabase.instance.client
              .from('loan_application')
              .update({
                'status': 'Approved',
                'reviewed_by': staffId,
                'date_reviewed': DateTime.now().toIso8601String(),
                'remarks': remarksController.text,
              })
              .eq('application_id', loanId);

          // 2. Notify via edge function
          await _notifyLoanStatus(loanId);

          // 3. Prepare approved_loans payload
          final approvedLoanPayload = {
            'member_id': loanRecord['member_id'],
            'installment': loanRecord['installment'],
            'repayment_term': loanRecord['repayment_term'],
            'status': 'Approved',
            'approved_by': staffId,
            'loan_amount': loanRecord['loan_amount'],
            'annual_income': loanRecord['annual_income'],
            'business_type': loanRecord['business_type'],
            'reason': loanRecord['reason'],
            'member_first_name': loanRecord['member_first_name'],
            'member_last_name': loanRecord['member_last_name'],
            'member_birth_date': loanRecord['member_birth_date'],
            'comaker_spouse_first_name': loanRecord['comaker_spouse_first_name'],
            'comaker_spouse_last_name': loanRecord['comaker_spouse_last_name'],
            'comaker_child_first_name': loanRecord['comaker_child_first_name'],
            'comaker_child_last_name': loanRecord['comaker_child_last_name'],
            'member_email': loanRecord['member_email'],
            'member_phone': loanRecord['member_phone'],
            'address': loanRecord['address'],
            'consent': loanRecord['consent'],
          };

          // 4. Insert into approved_loans
          await Supabase.instance.client
              .from('approved_loans')
              .insert(approvedLoanPayload);

          // 5. Delete the original record from loan_application
          await Supabase.instance.client
              .from('loan_application')
              .delete()
              .eq('application_id', loanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Loan approved and moved to approved_loans."))
          );

        } else if (status == 'Rejected') {
          // REJECTION FLOW
          // Update the loan_application table with rejection details
          await Supabase.instance.client
              .from('loan_application')
              .update({
                'status': 'Rejected',
                'reviewed_by': staffId,
                'date_reviewed': DateTime.now().toIso8601String(),
                'remarks': remarksController.text,
              })
              .eq('application_id', loanId);

          // Notify via edge function about rejection
          await _notifyLoanStatus(loanId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Loan rejected successfully."))
          );
        }

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

  // Helper to call the deployed edge function to notify applicant by email
  Future<void> _notifyLoanStatus(int loanId) async {
    final url = Uri.parse('https://thgmovkioubrizajsvze.supabase.co/functions/v1/send-loan-status-email');
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loan_id': loanId}),
      );
      if (resp.statusCode != 200) {
        debugPrint('[notifyLoanStatus] Function responded ${resp.statusCode}: ${resp.body}');
      } else {
        debugPrint('[notifyLoanStatus] Email notification sent for loan $loanId');
      }
    } catch (e) {
      debugPrint('[notifyLoanStatus] Error calling edge function: $e');
    }
  }

  int? _parseIntCandidate(dynamic candidate) {
    if (candidate == null) return null;
    if (candidate is int) return candidate;
    if (candidate is num) return candidate.toInt();
    if (candidate is String) {
      return int.tryParse(candidate);
    }
    if (candidate is Map) {
      // try common nested keys
      final v = candidate['value'] ?? candidate['id'] ?? candidate['application_id'];
      return _parseIntCandidate(v);
    }
    return null;
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
              hint: const Text('Choose'),
              items: [
                const DropdownMenuItem(
                    value: "Approved",
                    child: Text("Approve")),
                const DropdownMenuItem(
                    value: "Rejected",
                    child: Text("Reject")),
              ],
              onChanged: (value) {
                setState(() {
                  decision = value;
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
        // Single Confirm button (disabled until a real decision is chosen)
        ElevatedButton(
          onPressed: decision == null ? null : () => updateLoanStatus(decision!),
          style: ElevatedButton.styleFrom(
            backgroundColor: decision == 'Approved'
                ? Colors.green
                : (decision == 'Rejected' ? Colors.red : Colors.grey),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: const Text(
            "Confirm",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
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