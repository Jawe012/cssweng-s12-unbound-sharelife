import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFinanceManagement extends StatefulWidget {
  const AdminFinanceManagement({super.key});

  @override
  State<AdminFinanceManagement> createState() => _AdminFinanceManagementState();
}

class _AdminFinanceManagementState extends State<AdminFinanceManagement> {
  bool vouchersGenerated = false;
  bool isGeneratingVouchers = false;
  String? selectedTimePeriod;
  List<Map<String, dynamic>> revenueData = [];
  bool isLoadingReport = false;
  int? sortColumnIndex;
  bool isAscending = true;

  Future<void> _generateVouchers() async {
    setState(() {
      isGeneratingVouchers = true;
      vouchersGenerated = false;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Fetch all active approved loans
      final loansRes = await supabase
          .from('approved_loans')
          .select('application_id, member_first_name, member_last_name, loan_amount')
          .eq('status', 'active');

      // TODO: Implement actual voucher generation logic
      // This would typically involve creating voucher records in a database table
      // For now, we'll just simulate the operation
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        vouchersGenerated = true;
        isGeneratingVouchers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vouchers generated for ${(loansRes as List).length} active loans'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() => isGeneratingVouchers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating vouchers: $e')),
      );
    }
  }

  Future<void> _generateReport() async {
    if (selectedTimePeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a time period')),
      );
      return;
    }

    setState(() => isLoadingReport = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Fetch all approved loans
      final loansRes = await supabase
          .from('approved_loans')
          .select('application_id, loan_amount, status, created_at, repayment_term');

      // Fetch all validated payments
      final paymentsRes = await supabase
          .from('payments')
          .select('approved_loan_id, amount, payment_date, created_at')
          .eq('status', 'Validated');

      final loans = loansRes as List;
      final payments = paymentsRes as List;

      // Group data by time period and calculate metrics
      Map<String, Map<String, dynamic>> periodData = {};

      // Process loans
      for (var loan in loans) {
        final date = DateTime.parse(loan['created_at']);
        final periodKey = _getPeriodKey(date);

        if (!periodData.containsKey(periodKey)) {
          periodData[periodKey] = {
            'date': periodKey,
            'totalLoans': 0,
            'totalDisbursement': 0.0,
            'totalInterest': 0.0,
            'outstandingBalance': 0.0,
            'overdueAmounts': 0.0,
          };
        }

        final amount = (loan['loan_amount'] is num) 
            ? (loan['loan_amount'] as num).toDouble() 
            : 0.0;

        periodData[periodKey]!['totalLoans'] = (periodData[periodKey]!['totalLoans'] as int) + 1;
        periodData[periodKey]!['totalDisbursement'] = (periodData[periodKey]!['totalDisbursement'] as double) + amount;

        // Calculate interest (assuming 10% for demo)
        final interest = amount * 0.10;
        periodData[periodKey]!['totalInterest'] = (periodData[periodKey]!['totalInterest'] as double) + interest;

        // Calculate outstanding balance (loan amount - payments)
        final loanPayments = payments.where((p) => p['approved_loan_id'] == loan['application_id']);
        final totalPaid = loanPayments.fold<double>(0.0, (sum, p) {
          final amt = (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
          return sum + amt;
        });
        final outstanding = amount - totalPaid;
        if (outstanding > 0) {
          periodData[periodKey]!['outstandingBalance'] = (periodData[periodKey]!['outstandingBalance'] as double) + outstanding;
        }

        // TODO: Calculate actual overdue amounts based on repayment schedule
        // For now, using a placeholder calculation
        if (loan['status'] == 'Overdue') {
          periodData[periodKey]!['overdueAmounts'] = (periodData[periodKey]!['overdueAmounts'] as double) + outstanding;
        }
      }

      setState(() {
        revenueData = periodData.values.toList();
        isLoadingReport = false;
      });

    } catch (e) {
      setState(() => isLoadingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  String _getPeriodKey(DateTime date) {
    switch (selectedTimePeriod) {
      case 'Monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'Quarterly':
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return '${date.year}-Q$quarter';
      case 'Yearly':
        return '${date.year}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
  }

  void _sortReport(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0: // Date
          revenueData.sort((a, b) => ascending
              ? a['date'].compareTo(b['date'])
              : b['date'].compareTo(a['date']));
          break;
        case 1: // Total Loans
          revenueData.sort((a, b) => ascending
              ? (a['totalLoans'] as int).compareTo(b['totalLoans'] as int)
              : (b['totalLoans'] as int).compareTo(a['totalLoans'] as int));
          break;
        case 2: // Disbursement
          revenueData.sort((a, b) => ascending
              ? (a['totalDisbursement'] as double).compareTo(b['totalDisbursement'] as double)
              : (b['totalDisbursement'] as double).compareTo(a['totalDisbursement'] as double));
          break;
        case 3: // Interest
          revenueData.sort((a, b) => ascending
              ? (a['totalInterest'] as double).compareTo(b['totalInterest'] as double)
              : (b['totalInterest'] as double).compareTo(a['totalInterest'] as double));
          break;
        case 4: // Outstanding
          revenueData.sort((a, b) => ascending
              ? (a['outstandingBalance'] as double).compareTo(b['outstandingBalance'] as double)
              : (b['outstandingBalance'] as double).compareTo(a['outstandingBalance'] as double));
          break;
        case 5: // Overdue
          revenueData.sort((a, b) => ascending
              ? (a['overdueAmounts'] as double).compareTo(b['overdueAmounts'] as double)
              : (b['overdueAmounts'] as double).compareTo(a['overdueAmounts'] as double));
          break;
      }
    });
  }

  void _downloadReport() {
    // TODO: Implement CSV/PDF download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download functionality coming soon')),
    );
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
                        constraints: BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              "Finance Management",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Generate Vouchers and Revenue Reports",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            SizedBox(height: 32),

                            // Voucher Generation Section
                            Container(
                              padding: EdgeInsets.all(24),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: isGeneratingVouchers ? null : _generateVouchers,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: isGeneratingVouchers
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Generate Vouchers",
                                            style: TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Click to generate vouchers for all approved and active loans",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  if (vouchersGenerated) ...[
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          "Vouchers generated for all reports",
                                          style: TextStyle(color: Colors.green, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  SizedBox(height: 32),
                                  Divider(),
                                  SizedBox(height: 24),

                                  // Revenue Report Section
                                  Text(
                                    "Revenue Report",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 16),

                                  // Report Controls
                                  Row(
                                    children: [
                                      // Time Period Dropdown
                                      Container(
                                        width: 200,
                                        height: 40,
                                        child: DropdownButtonFormField<String>(
                                          value: selectedTimePeriod,
                                          decoration: InputDecoration(
                                            labelText: "Time period",
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          items: [
                                            DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                                            DropdownMenuItem(value: "Quarterly", child: Text("Quarterly")),
                                            DropdownMenuItem(value: "Yearly", child: Text("Yearly")),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              selectedTimePeriod = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),

                                      // Create Report Button
                                      ElevatedButton(
                                        onPressed: isLoadingReport ? null : _generateReport,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: isLoadingReport
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                "Create Report",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                      ),
                                      SizedBox(width: 16),

                                      // Download Report Button
                                      ElevatedButton(
                                        onPressed: revenueData.isEmpty ? null : _downloadReport,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          "Download Report",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),

                                  // Revenue Report Table
                                  if (revenueData.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          sortColumnIndex: sortColumnIndex,
                                          sortAscending: isAscending,
                                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                          columns: [
                                            DataColumn(
                                              label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                            DataColumn(
                                              label: Text("Total Approved\nLoans", style: TextStyle(fontWeight: FontWeight.bold)),
                                              numeric: true,
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                            DataColumn(
                                              label: Text("Total\nDisbursement", style: TextStyle(fontWeight: FontWeight.bold)),
                                              numeric: true,
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                            DataColumn(
                                              label: Text("Total Interest\nEarned", style: TextStyle(fontWeight: FontWeight.bold)),
                                              numeric: true,
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                            DataColumn(
                                              label: Text("Outstanding\nBalances", style: TextStyle(fontWeight: FontWeight.bold)),
                                              numeric: true,
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                            DataColumn(
                                              label: Text("Total Overdue\nAmounts", style: TextStyle(fontWeight: FontWeight.bold)),
                                              numeric: true,
                                              onSort: (i, asc) => _sortReport(i, asc),
                                            ),
                                          ],
                                          rows: revenueData.map((data) {
                                            return DataRow(cells: [
                                              DataCell(Text(data['date'])),
                                              DataCell(Text(data['totalLoans'].toString())),
                                              DataCell(Text('₱${(data['totalDisbursement'] as double).toStringAsFixed(2)}')),
                                              DataCell(Text('₱${(data['totalInterest'] as double).toStringAsFixed(2)}')),
                                              DataCell(Text('₱${(data['outstandingBalance'] as double).toStringAsFixed(2)}')),
                                              DataCell(Text('₱${(data['overdueAmounts'] as double).toStringAsFixed(2)}')),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                  if (revenueData.isEmpty && !isLoadingReport)
                                    Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Center(
                                        child: Text(
                                          "Select a time period and click 'Create Report' to view revenue data",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                ],
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