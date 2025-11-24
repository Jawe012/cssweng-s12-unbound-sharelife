import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberPaymentHistory extends StatefulWidget {
  const MemberPaymentHistory({super.key});

  @override
  State<MemberPaymentHistory> createState() => _MemberPaymentHistoryState();
}

class _MemberPaymentHistoryState extends State<MemberPaymentHistory> {
  int? sortColumnIndex;
  bool isAscending = false; 
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  bool isLoading = true;
  double buttonHeight = 28;

  // Summary stats
  double totalPaid = 0.0;
  int totalPayments = 0;
  double pendingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        debugPrint('[PaymentHistory] No authenticated user');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      debugPrint('[PaymentHistory] Fetching payment history for user: ${user.email}');

      // Get user's approved loans
      final loansRes = await supabase
          .from('approved_loans')
          .select('application_id, loan_amount, repayment_term, member_first_name, member_last_name')
          .eq('member_email', user.email!);

      debugPrint('[PaymentHistory] approved_loans query raw result type: ${loansRes.runtimeType}');
      try {
        final loansPreview = (loansRes as List).take(3).toList();
        debugPrint('[PaymentHistory] approved_loans query raw result preview: $loansPreview');
      } catch (e) {
        debugPrint('[PaymentHistory] approved_loans preview error: $e');
      }

      final loans = loansRes as List;
      if (loans.isEmpty) {
        debugPrint('[PaymentHistory] No approved loans found');

        // Diagnostic: also check the `member_loans` view (if present) to see if the view contains rows
        try {
          // Lookup member_id first (the view exposes `member_id`, not `member_email`)
          try {
            final memberRec = await supabase
              .from('members')
              .select('id')
              .eq('email_address', user.email!)
              .maybeSingle();

            debugPrint('[PaymentHistory] member lookup result: $memberRec');

            if (memberRec != null && memberRec['id'] != null) {
              final memberId = memberRec['id'];
              final viewRes = await supabase
                  .from('member_loans')
                  .select('*')
                  .eq('member_id', memberId);

              debugPrint('[PaymentHistory] member_loans view query type: ${viewRes.runtimeType}');
              try {
                final viewPreview = (viewRes as List).take(5).toList();
                debugPrint('[PaymentHistory] member_loans view preview: $viewPreview');
              } catch (e) {
                debugPrint('[PaymentHistory] member_loans preview error: $e');
              }
            } else {
              debugPrint('[PaymentHistory] Member record not found for email ${user.email}; cannot query member_loans by member_id');
            }
          } catch (memberErr) {
            debugPrint('[PaymentHistory] Error looking up member by email: $memberErr');
          }
        } catch (viewErr) {
          debugPrint('[PaymentHistory] Error querying member_loans view: $viewErr');
        }
        if (mounted) {
          setState(() {
            isLoading = false;
            payments = [];
            filteredPayments = [];
          });
        }
        return;
      }

      final loanIds = loans.map((loan) => loan['application_id']).toList();
      debugPrint('[PaymentHistory] Found ${loanIds.length} loans: $loanIds');

      // Extra diagnostic: print the loan objects themselves (limited preview)
      try {
        debugPrint('[PaymentHistory] loans preview: ${loans.take(5).toList()}');
      } catch (e) {
        debugPrint('[PaymentHistory] Error printing loans preview: $e');
      }

      // get all payments for loans
      final paymentsRes = await supabase
          .from('payments')
          .select('payment_id, approved_loan_id, amount, payment_date, installment_number, payment_type, bank_name, gcash_reference, gcash_screenshot_path, status, created_at, staff_id')
          .inFilter('approved_loan_id', loanIds)
          .order('created_at', ascending: false);

      final fetchedPayments = (paymentsRes as List).cast<Map<String, dynamic>>();
      debugPrint('[PaymentHistory] Fetched ${fetchedPayments.length} payments');

      final loanMap = {for (var loan in loans) loan['application_id']: loan};
      
      // Fetch staff names for payments
      final enrichedPayments = <Map<String, dynamic>>[];
      for (var payment in fetchedPayments) {
        final loanId = payment['approved_loan_id'];
        final loan = loanMap[loanId];
        
        String staffName = 'N/A';
        final staffId = payment['staff_id'];
        if (staffId != null) {
          try {
            final staffRes = await supabase
                .from('staff')
                .select('first_name, last_name')
                .eq('id', staffId)
                .maybeSingle();
            if (staffRes != null) {
              staffName = '${staffRes['first_name']} ${staffRes['last_name']}';
            }
          } catch (e) {
            debugPrint('[PaymentHistory] Error fetching staff for payment ${payment['payment_id']}: $e');
          }
        }
        
        enrichedPayments.add({
          ...payment,
          'loan_amount': loan?['loan_amount'] ?? 0,
          'repayment_term': loan?['repayment_term'] ?? 'N/A',
          'member_name': '${loan?['member_first_name'] ?? ''} ${loan?['member_last_name'] ?? ''}'.trim(),
          'staff_name': staffName,
        });
      }

      // summary stats - only count approved payments for total
      double total = 0.0;
      double pending = 0.0;
      int approvedCount = 0;
      for (var payment in enrichedPayments) {
        final amount = (payment['amount'] is num)
            ? (payment['amount'] as num).toDouble()
            : double.tryParse(payment['amount'].toString()) ?? 0.0;

        final status = payment['status']?.toString() ?? '';
        final statusNorm = status.toLowerCase();

        // Treat both 'Approved' and legacy/alternate 'Validated' as approved
        if (statusNorm == 'approved' || statusNorm == 'validated') {
          total += amount;
          approvedCount++;
        } else if (statusNorm.contains('pending')) {
          // any pending-like status counts toward pendingAmount
          pending += amount;
        }
      }

      if (mounted) {
        setState(() {
          payments = enrichedPayments;
          filteredPayments = enrichedPayments;
          totalPaid = total;
          totalPayments = approvedCount;
          pendingAmount = pending;
          isLoading = false;
        });
      }

  debugPrint('[PaymentHistory] Loaded ${payments.length} payments. Total: ${ExportService.currencyFormat.format(totalPaid)}');

    } catch (e) {
      debugPrint('[PaymentHistory] Error fetching payment history: $e');
      if (mounted) setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment history: $e')),
        );
      }
    }
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0: // payment id
          filteredPayments.sort((a, b) => ascending
              ? (a["payment_id"] ?? 0).compareTo(b["payment_id"] ?? 0)
              : (b["payment_id"] ?? 0).compareTo(a["payment_id"] ?? 0));
          break;
        case 1: // loan ref
          filteredPayments.sort((a, b) => ascending
              ? (a["approved_loan_id"] ?? 0).compareTo(b["approved_loan_id"] ?? 0)
              : (b["approved_loan_id"] ?? 0).compareTo(a["approved_loan_id"] ?? 0));
          break;
        case 2: // installment #
          filteredPayments.sort((a, b) => ascending
              ? (a["installment_number"] ?? 0).compareTo(b["installment_number"] ?? 0)
              : (b["installment_number"] ?? 0).compareTo(a["installment_number"] ?? 0));
          break;
        case 3: // amount
          filteredPayments.sort((a, b) {
            final aAmt = (a["amount"] is num) ? (a["amount"] as num).toDouble() : double.tryParse(a["amount"].toString()) ?? 0.0;
            final bAmt = (b["amount"] is num) ? (b["amount"] as num).toDouble() : double.tryParse(b["amount"].toString()) ?? 0.0;
            return ascending ? aAmt.compareTo(bAmt) : bAmt.compareTo(aAmt);
          });
          break;
        case 4: // payment type
          filteredPayments.sort((a, b) => ascending
              ? (a["payment_type"] ?? '').compareTo(b["payment_type"] ?? '')
              : (b["payment_type"] ?? '').compareTo(a["payment_type"] ?? ''));
          break;
        case 5: // reference
          filteredPayments.sort((a, b) {
            final aRef = a["gcash_reference"] ?? a["bank_name"] ?? '';
            final bRef = b["gcash_reference"] ?? b["bank_name"] ?? '';
            return ascending ? aRef.compareTo(bRef) : bRef.compareTo(aRef);
          });
          break;
        case 6: // payment date
          filteredPayments.sort((a, b) {
            final aDate = DateTime.tryParse(a["payment_date"] ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b["payment_date"] ?? '') ?? DateTime(1970);
            return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          });
          break;
        case 7: // status
          filteredPayments.sort((a, b) => ascending
              ? (a["status"] ?? '').compareTo(b["status"] ?? '')
              : (b["status"] ?? '').compareTo(a["status"] ?? ''));
          break;
      }
    });
  }

  Widget summaryCards() {
    return Row(
      children: [
        // total paid
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Paid",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(ExportService.currencyFormat.format(totalPaid)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // total payments
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Payments",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("$totalPayments"),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // pending approval
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pending Approval",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(ExportService.currencyFormat.format(pendingAmount)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget filters() {
    return Row(
      children: [
        // payment id search
        SizedBox(
          width: 160,
          height: buttonHeight,
          child: TextField(
            decoration: InputDecoration(
              labelText: "Payment ID",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  filteredPayments = payments;
                } else {
                  filteredPayments = payments
                      .where((payment) => payment["payment_id"]
                          .toString()
                          .contains(value))
                      .toList();
                }
              });
            },
          ),
        ),
        SizedBox(width: 16),

        // start date
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: TextField(
            decoration: InputDecoration(
              labelText: "Start Date",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // end date
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: TextField(
            decoration: InputDecoration(
              labelText: "End Date",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // refresh button
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _fetchPaymentHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(80, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              "Refresh",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        Spacer(),

        // download button
        ExportDropdownButton(
          height: buttonHeight,
          minWidth: 100,
          onExportPdf: () async {
            await ExportService.exportAndSharePdf(
              context: context,
              title: 'Payment History',
              rows: filteredPayments,
              filename: 'payment_history.pdf',
              columnOrder: ['payment_id', 'payment_date', 'amount', 'payment_type', 'status'],
              columnHeaders: {
                'payment_id': 'Payment ID',
                'payment_date': 'Date',
                'amount': 'Amount',
                'payment_type': 'Type',
                'status': 'Status',
              },
            );
          },
          onExportXlsx: () async {
            await ExportService.exportAndShareExcel(
              context: context,
              rows: filteredPayments,
              filename: 'payment_history.xlsx',
              sheetName: 'Payment History',
              columnOrder: ['payment_id', 'payment_date', 'amount', 'payment_type', 'status'],
              columnHeaders: {
                'payment_id': 'Payment ID',
                'payment_date': 'Date',
                'amount': 'Amount',
                'payment_type': 'Type',
                'status': 'Status',
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getReference(Map<String, dynamic> payment) {
    if (payment['payment_type'] == 'Gcash' && payment['gcash_reference'] != null) {
      return payment['gcash_reference'];
    } else if (payment['payment_type'] == 'Bank Transfer' && payment['bank_name'] != null) {
      return payment['bank_name'];
    } else {
      return 'N/A';
    }
  }

  Future<void> _viewScreenshot(String? path) async {
    if (path == null) return;
    
    try {
      final publicUrl = Supabase.instance.client.storage
          .from('payment_receipts')
          .getPublicUrl(path);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Payment Screenshot'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      publicUrl,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading screenshot: $e')),
        );
      }
    }
  }

  Widget paymentsTable() {
    if (isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredPayments.isEmpty) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No payment history found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Your payment records will appear here once you make a payment',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 24,
                    columns: [
                      DataColumn(
                          label: Text("Payment ID",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Loan Ref",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Inst. #",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Amount",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Type",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Reference",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Staff",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Screenshot",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Payment Date",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Status",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                    ],
                    rows: filteredPayments
                        .map(
                          (payment) => DataRow(cells: [
                            DataCell(Text(payment["payment_id"].toString())),
                            DataCell(Text(payment["approved_loan_id"].toString())),
                            DataCell(Text(payment["installment_number"]?.toString() ?? 'N/A')),
                            DataCell(Text(ExportService.safeCurrency(payment["amount"]))),
                            DataCell(Text(payment["payment_type"] ?? 'N/A')),
                            DataCell(Text(_getReference(payment))),
                            DataCell(Text(payment["staff_name"] ?? 'N/A')),
                            DataCell(
                              payment["gcash_screenshot_path"] != null
                                  ? InkWell(
                                      onTap: () => _viewScreenshot(payment["gcash_screenshot_path"]),
                                      child: Text(
                                        'View',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    )
                                  : Text('N/A', style: TextStyle(color: Colors.grey)),
                            ),
                            DataCell(Text(_formatDate(payment["payment_date"]))),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: payment["status"] == 'Approved'
                                      ? Colors.green.withOpacity(0.1)
                                      : payment["status"] == 'Pending Approval'
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment["status"] ?? 'N/A',
                                  style: TextStyle(
                                    color: payment["status"] == 'Approved'
                                        ? Colors.green.shade700
                                        : payment["status"] == 'Pending Approval'
                                            ? Colors.orange.shade700
                                            : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
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
          TopNavBar(splash: "Member"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // sidebar
                SideMenu(role: "Member"),

                // main content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // title
                          Text(
                            "My Payments",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "View your complete payment history and transaction details.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 24),

                          // filter row
                          filters(),
                          SizedBox(height: 24),

                          // summary cards
                          summaryCards(),
                          SizedBox(height: 24),

                          // payments table
                          paymentsTable(),
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
