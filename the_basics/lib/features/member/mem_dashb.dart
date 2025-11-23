import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberDB extends StatefulWidget {
  const MemberDB({super.key});

  @override
  State<MemberDB> createState() => _MemDBState();
}

class _MemDBState extends State<MemberDB> {
  int? sortColumnIndex;
  bool isAscending = true;
  List<Map<String, dynamic>> loans = [];
  double buttonHeight = 28;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberLoans();
  }

  Future<void> _fetchMemberLoans() async {
    setState(() => _isLoading = true);
    try {
      // Get current user's member_id from auth
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          loans = [];
          _isLoading = false;
        });
        return;
      }

      // Get member info
      final memberResponse = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse == null) {
        setState(() {
          loans = [];
          _isLoading = false;
        });
        return;
      }

      final memberId = memberResponse['id'];

      // Fetch loans for this member
      final response = await Supabase.instance.client
          .from('approved_loans')
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedLoans = [];
      
      for (var loan in response) {
        final createdAt = loan['created_at'] != null 
            ? DateTime.parse(loan['created_at']) 
            : DateTime.now();
        final year = createdAt.year;
        final loanId = 'LN-$year-${loan['application_id']?.toString().padLeft(4, '0') ?? '0000'}';

        final startDate = loan['created_at'] != null 
            ? DateTime.parse(loan['created_at']) 
            : DateTime.now();
        final dueDate = _calculateDueDate(startDate, loan['repayment_term']);

        fetchedLoans.add({
          'ref': loanId,
          'amt': loan['loan_amount'] ?? 0,
          'interest': loan['interest_rate'] ?? 0,
          'start': startDate.toString().split(' ')[0],
          'due': dueDate.toString().split(' ')[0],
          'instType': loan['repayment_term'] != null ? '${loan['repayment_term']} months' : 'N/A',
          'totalInst': loan['repayment_term'] ?? 0,
          'instAmt': loan['repayment_term'] != null && loan['repayment_term'] > 0
              ? ((loan['loan_amount'] ?? 0) / loan['repayment_term']).toStringAsFixed(2)
              : '0.00',
          'status': loan['status'] ?? 'unknown',
        });
      }

      setState(() {
        loans = fetchedLoans;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching member loans: $e');
      setState(() {
        loans = [];
        _isLoading = false;
      });
    }
  }

  DateTime _calculateDueDate(DateTime startDate, int? repaymentTerm) {
    if (repaymentTerm == null || repaymentTerm == 0) {
      return startDate.add(Duration(days: 30));
    }
    return DateTime(
      startDate.year,
      startDate.month + repaymentTerm,
      startDate.day,
    );
  }

  // Sum loan amounts (robust to int/double/string values)
  double _sumLoanAmounts() {
    return loans.fold(0.0, (double prev, l) {
      final amt = l['amt'];
      if (amt == null) return prev;
      if (amt is num) return prev + amt.toDouble();
      if (amt is String) {
        final parsed = double.tryParse(amt.replaceAll(RegExp(r'[^0-9\.-]'), ''));
        return prev + (parsed ?? 0.0);
      }
      return prev;
    });
  }

  String _formatCurrency(double value) {
    // Format with comma thousand separators, drop decimals when .00
    if (value == value.roundToDouble()) {
      final intVal = value.toInt();
      final s = intVal.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
      return 'Php $s';
    }
    final s = value.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return 'Php $intPart.${parts[1]}';
  }



  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0:
          loans.sort((a, b) => ascending
              ? a["ref"].compareTo(b["ref"])
              : b["ref"].compareTo(a["ref"]));
          break;
        case 1:
          loans.sort((a, b) => ascending
              ? a["amt"].compareTo(b["amt"])
              : b["amt"].compareTo(a["amt"]));
          break;
        case 2:
          loans.sort((a, b) => ascending
              ? a["interest"].compareTo(b["interest"])
              : b["interest"].compareTo(a["interest"]));
          break;
        case 3:
          loans.sort((a, b) => ascending
              ? a["start"].compareTo(b["start"])
              : b["start"].compareTo(a["start"]));
          break;
        case 4:
          loans.sort((a, b) => ascending
              ? a["due"].compareTo(b["due"])
              : b["due"].compareTo(a["due"]));
          break;
        case 5:
          loans.sort((a, b) => ascending
              ? a["instType"].compareTo(b["instType"])
              : b["instType"].compareTo(a["instType"]));
          break;
        case 6:
          loans.sort((a, b) => ascending
              ? a["totalInst"].compareTo(b["totalInst"])
              : b["totalInst"].compareTo(a["totalInst"]));
          break;
        case 7:
          loans.sort((a, b) => ascending
              ? a["instAmt"].compareTo(b["instAmt"])
              : b["instAmt"].compareTo(a["instAmt"]));
          break;
        case 8:
          loans.sort((a, b) => ascending
              ? a["status"].compareTo(b["status"])
              : b["status"].compareTo(a["status"]));
          break;
      }
    });
  }

  Widget summaryCards() {
    final totalLoan = _sumLoanAmounts();
    final principalRepayment = 0.0; // Replace with real data if available
    final outstandingBalance = (totalLoan - principalRepayment).clamp(0.0, double.infinity);

    return Row(
      children: [

        // Principal repayment
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
                Text("Principal Repayment",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(principalRepayment)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // Outstanding balance
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
                Text("Outstanding Balance",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(outstandingBalance)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // Total loan amount
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
                Text("Total Loan Amount",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(totalLoan)),
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
        // Reference number search
        SizedBox(
          width: 160,
          height: buttonHeight,
          child: TextField(
            decoration: InputDecoration(
              labelText: "Ref. No.",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (value) {
              // Filter logic can be implemented here
            },
          ),
        ),
        SizedBox(width: 16),

        // Start date
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
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // End date
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
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // Search button
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _fetchMemberLoans,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(80, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              "Search",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        Spacer(),

        // Download button
        ExportDropdownButton(
          height: buttonHeight,
          minWidth: 100,
          onExportPdf: () async {
            await ExportService.exportAndSharePdf(
              context: context,
              title: 'Loan Dashboard',
              rows: loans,
              filename: 'loan_dashboard.pdf',
              columnOrder: ['ref', 'amt', 'start', 'due', 'pay', 'stat'],
              columnHeaders: {
                'ref': 'Loan ID',
                'amt': 'Amount',
                'start': 'Start Date',
                'due': 'Due Date',
                'pay': 'Payment',
                'stat': 'Status',
              },
            );
          },
          onExportXlsx: () async {
            await ExportService.exportAndShareExcel(
              context: context,
              rows: loans,
              filename: 'loan_dashboard.xlsx',
              sheetName: 'Loans',
              columnOrder: ['ref', 'amt', 'start', 'due', 'pay', 'stat'],
              columnHeaders: {
                'ref': 'Loan ID',
                'amt': 'Amount',
                'start': 'Start Date',
                'due': 'Due Date',
                'pay': 'Payment',
                'stat': 'Status',
              },
            );
          },
        ),
      ],
    );
  }

  Widget amortizationTable() {
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
                    columnSpacing: 58,
                    columns: [
                      DataColumn(
                          label: Text("Ref. No.", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Interest", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Due Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Inst Type", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Total Inst", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Inst Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                    ],
                    rows: loans
                        .map(
                          (loan) => DataRow(cells: [
                            DataCell(Text(loan["ref"])),
                            DataCell(Text(ExportService.currencyFormat.format((loan["amt"] is num) ? loan["amt"] : double.tryParse(loan["amt"].toString()) ?? 0))),
                            DataCell(Text("${loan["interest"]}%")),
                            DataCell(Text(loan["start"])),
                            DataCell(Text(loan["due"])),
                            DataCell(Text(loan["instType"])),
                            DataCell(Text("${loan["totalInst"]}")),
                            DataCell(Text(ExportService.currencyFormat.format((loan["instAmt"] is num) ? loan["instAmt"] : double.tryParse(loan["instAmt"].toString()) ?? 0))),
                            DataCell(Text(loan["status"])),
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
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          Text(
                            "Your Loans",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "View your loan applications and their statuses.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 24),

                          // filter row
                          filters(),
                          SizedBox(height: 24),

                          // summary cards
                          summaryCards(),
                          SizedBox(height: 24),

                          // amortization table
                          amortizationTable(),
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