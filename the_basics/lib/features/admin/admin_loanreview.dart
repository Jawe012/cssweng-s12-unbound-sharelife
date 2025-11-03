import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LoanReviewPage extends StatefulWidget {
  const LoanReviewPage({super.key});

  @override
  State<LoanReviewPage> createState() => _LoanReviewPageState();
}

String formatDate(dynamic timestamp) {
  if (timestamp == null) return 'Unknown';
  try {
    if (timestamp is DateTime) {
      final d = timestamp;
      return "${d.month}/${d.day}/${d.year}";
    } else if (timestamp is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return "${d.month}/${d.day}/${d.year}";
    } else {
      final d = DateTime.parse(timestamp.toString());
      return "${d.month}/${d.day}/${d.year}";
    }
  } catch (_) {
    return 'Unknown';
  }
}


class _LoanReviewPageState extends State<LoanReviewPage> {
  int? sortColumnIndex;
  bool isAscending = true;
  List<Map<String, dynamic>> loans = [];
  double buttonHeight = 28;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchLoans();
    
    // Set up periodic refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchLoans();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

 Future<void> fetchLoans() async {
  try {
    // Fetch from loan_application table - only Pending or null status
    final loanAppResp = await Supabase.instance.client
        .from('loan_application')
        .select('application_id, member_first_name, member_last_name, loan_amount, reason, created_at, status')
        .or('status.eq.Pending,status.is.null');

    if (!mounted) return;

    setState(() {
      loans = [];
      
      // Add loans from loan_application table
      for (var loan in loanAppResp) {
        // Normalize the ID field to 'id' for consistent handling
        final normalizedLoan = Map<String, dynamic>.from(loan);
        normalizedLoan['id'] = loan['application_id'];
        normalizedLoan['source'] = 'loan_application';
        loans.add(normalizedLoan);
      }
    });
    
    print("Fetched ${loans.length} total pending loans");
  } catch (e) {
    print('fetchLoans error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading loans: $e'))
      );
    }
  }
  }

  Widget buildStatus(int number) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number Applications Pending',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget applicationsTable() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder:(context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Applicant", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Loan Type", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Date Submitted", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: loans.map((loan) {
                  return _buildRow(loan);
                }).toList(), //rows logic
              ),
            );
          }
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Column(
        children: [
          // top nav bar
          TopNavBar(splash: "Admin"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                SideMenu(role: "Admin"),

                // main content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          Text(
                            "Loan Review",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Review and approve/reject pending loan applications.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 24),

                          // pending loans
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              buildStatus(loans.length),
                            ],
                          ),

                          // filter row
                          SizedBox(height: 24),

                          // table
                          applicationsTable(),
                          SizedBox(height: 24),

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

  DataRow _buildRow(Map<String, dynamic> loan) {
    final applicant = "${loan['member_first_name'] ?? ''} ${loan['member_last_name'] ?? ''}";
    final amount = '₱${loan['loan_amount'] ?? 0}';
    final type = loan['reason'] ?? 'N/A';
    final date = formatDate(loan['created_at']);

    return DataRow(cells: [
      DataCell(Text(applicant)),
      DataCell(Text(amount)),
      DataCell(Text(type)),
      DataCell(Text(date)),
      DataCell(ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/admin-loanrevdetails',
            arguments: loan['id'], // pass the normalized ID
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text("Review", style: TextStyle(color: Colors.white)),
      )),
    ]);
  }
}