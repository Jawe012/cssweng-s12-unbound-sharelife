import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRecords extends StatefulWidget {
  const AdminRecords({super.key});

  @override
  State<AdminRecords> createState() => _AdminRecordsState();
}

class _AdminRecordsState extends State<AdminRecords> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Loans data
  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> filteredLoans = [];
  bool isLoadingLoans = true;
  int totalLoans = 0;
  double totalLoanAmount = 0.0;
  int activeLoans = 0;
  
  // Payments data
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  bool isLoadingPayments = true;
  int totalPayments = 0;
  double totalPaymentAmount = 0.0;
  int pendingPayments = 0;
  
  // Sorting
  int? loansSortColumnIndex;
  bool loansIsAscending = false;
  int? paymentsSortColumnIndex;
  bool paymentsIsAscending = false;
  
  double buttonHeight = 28;

  // Filter controllers - Loans
  final TextEditingController loanIdController = TextEditingController();
  final TextEditingController memberNameController = TextEditingController();
  String? selectedLoanStatus;
  
  // Filter controllers - Payments
  final TextEditingController paymentIdController = TextEditingController();
  final TextEditingController paymentLoanIdController = TextEditingController();
  String? selectedPaymentType;
  String? selectedPaymentStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchLoans();
    _fetchPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    loanIdController.dispose();
    memberNameController.dispose();
    paymentIdController.dispose();
    paymentLoanIdController.dispose();
    super.dispose();
  }

  // ===== LOANS TAB METHODS =====
  
  Future<void> _fetchLoans() async {
    setState(() => isLoadingLoans = true);

    try {
      final supabase = Supabase.instance.client;
      
      final loansRes = await supabase
          .from('approved_loans')
          .select('application_id, member_id, member_first_name, member_last_name, loan_amount, repayment_term, status, created_at, installment')
          .order('created_at', ascending: false);

      final fetchedLoans = (loansRes as List).cast<Map<String, dynamic>>();

      // Calculate summary stats
      int total = fetchedLoans.length;
      double totalAmt = 0.0;
      int active = 0;

      for (var loan in fetchedLoans) {
        final amount = (loan['loan_amount'] is num) 
            ? (loan['loan_amount'] as num).toDouble() 
            : double.tryParse(loan['loan_amount'].toString()) ?? 0.0;
        totalAmt += amount;
        
        if (loan['status']?.toString().toLowerCase() == 'active') {
          active++;
        }
      }

      setState(() {
        loans = fetchedLoans;
        filteredLoans = fetchedLoans;
        totalLoans = total;
        totalLoanAmount = totalAmt;
        activeLoans = active;
        isLoadingLoans = false;
      });

    } catch (e) {
      debugPrint('[AdminRecords] Error fetching loans: $e');
      setState(() => isLoadingLoans = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load loans: $e')),
        );
      }
    }
  }

  void _filterLoans() {
    setState(() {
      filteredLoans = loans.where((loan) {
        // Loan ID filter
        if (loanIdController.text.isNotEmpty) {
          if (!loan['application_id'].toString().contains(loanIdController.text)) {
            return false;
          }
        }
        
        // Member name filter
        if (memberNameController.text.isNotEmpty) {
          final fullName = '${loan['member_first_name']} ${loan['member_last_name']}'.toLowerCase();
          if (!fullName.contains(memberNameController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Status filter
        if (selectedLoanStatus != null && selectedLoanStatus != 'All') {
          if (loan['status']?.toString().toLowerCase() != selectedLoanStatus?.toLowerCase()) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _sortLoans(int columnIndex, bool ascending) {
    setState(() {
      loansSortColumnIndex = columnIndex;
      loansIsAscending = ascending;

      switch (columnIndex) {
        case 0: // Loan ID
          filteredLoans.sort((a, b) => ascending
              ? (a["application_id"] ?? 0).compareTo(b["application_id"] ?? 0)
              : (b["application_id"] ?? 0).compareTo(a["application_id"] ?? 0));
          break;
        case 1: // Member Name
          filteredLoans.sort((a, b) {
            final aName = '${a["member_first_name"]} ${a["member_last_name"]}';
            final bName = '${b["member_first_name"]} ${b["member_last_name"]}';
            return ascending ? aName.compareTo(bName) : bName.compareTo(aName);
          });
          break;
        case 2: // Amount
          filteredLoans.sort((a, b) {
            final aAmt = (a["loan_amount"] is num) ? (a["loan_amount"] as num).toDouble() : 0.0;
            final bAmt = (b["loan_amount"] is num) ? (b["loan_amount"] as num).toDouble() : 0.0;
            return ascending ? aAmt.compareTo(bAmt) : bAmt.compareTo(aAmt);
          });
          break;
        case 3: // Repayment Term
          filteredLoans.sort((a, b) => ascending
              ? (a["repayment_term"] ?? '').compareTo(b["repayment_term"] ?? '')
              : (b["repayment_term"] ?? '').compareTo(a["repayment_term"] ?? ''));
          break;
        case 4: // Status
          filteredLoans.sort((a, b) => ascending
              ? (a["status"] ?? '').compareTo(b["status"] ?? '')
              : (b["status"] ?? '').compareTo(a["status"] ?? ''));
          break;
        case 5: // Date
          filteredLoans.sort((a, b) {
            final aDate = DateTime.tryParse(a["created_at"] ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b["created_at"] ?? '') ?? DateTime(1970);
            return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          });
          break;
      }
    });
  }

  // ===== PAYMENTS TAB METHODS =====
  
  Future<void> _fetchPayments() async {
    setState(() => isLoadingPayments = true);

    try {
      final supabase = Supabase.instance.client;
      
      final paymentsRes = await supabase
          .from('payments')
          .select('''
            payment_id,
            approved_loan_id,
            amount,
            payment_type,
            payment_date,
            installment_number,
            status,
            created_at,
            approved_loans!inner(
              member_first_name,
              member_last_name
            )
          ''')
          .order('created_at', ascending: false);

      final fetchedPayments = (paymentsRes as List).map((payment) {
        return <String, dynamic>{
          ...payment as Map<String, dynamic>,
          'member_first_name': payment['approved_loans']['member_first_name'],
          'member_last_name': payment['approved_loans']['member_last_name'],
        };
      }).toList().cast<Map<String, dynamic>>();

      // Calculate summary stats
      int total = fetchedPayments.length;
      double totalAmt = 0.0;
      int pending = 0;

      for (var payment in fetchedPayments) {
        final amount = (payment['amount'] is num) 
            ? (payment['amount'] as num).toDouble() 
            : double.tryParse(payment['amount'].toString()) ?? 0.0;
        totalAmt += amount;
        
        if (payment['status'] == 'Pending Approval') {
          pending++;
        }
      }

      setState(() {
        payments = fetchedPayments;
        filteredPayments = fetchedPayments;
        totalPayments = total;
        totalPaymentAmount = totalAmt;
        pendingPayments = pending;
        isLoadingPayments = false;
      });

    } catch (e) {
      debugPrint('[AdminRecords] Error fetching payments: $e');
      setState(() => isLoadingPayments = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payments: $e')),
        );
      }
    }
  }

  void _filterPayments() {
    setState(() {
      filteredPayments = payments.where((payment) {
        // Payment ID filter
        if (paymentIdController.text.isNotEmpty) {
          if (!payment['payment_id'].toString().contains(paymentIdController.text)) {
            return false;
          }
        }
        
        // Loan ID filter
        if (paymentLoanIdController.text.isNotEmpty) {
          if (!payment['approved_loan_id'].toString().contains(paymentLoanIdController.text)) {
            return false;
          }
        }
        
        // Payment Type filter
        if (selectedPaymentType != null && selectedPaymentType != 'All') {
          if (payment['payment_type']?.toString() != selectedPaymentType) {
            return false;
          }
        }
        
        // Status filter
        if (selectedPaymentStatus != null && selectedPaymentStatus != 'All') {
          if (payment['status']?.toString() != selectedPaymentStatus) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _sortPayments(int columnIndex, bool ascending) {
    setState(() {
      paymentsSortColumnIndex = columnIndex;
      paymentsIsAscending = ascending;

      switch (columnIndex) {
        case 0: // Payment ID
          filteredPayments.sort((a, b) => ascending
              ? (a["payment_id"] ?? 0).compareTo(b["payment_id"] ?? 0)
              : (b["payment_id"] ?? 0).compareTo(a["payment_id"] ?? 0));
          break;
        case 1: // Loan ID
          filteredPayments.sort((a, b) => ascending
              ? (a["approved_loan_id"] ?? 0).compareTo(b["approved_loan_id"] ?? 0)
              : (b["approved_loan_id"] ?? 0).compareTo(a["approved_loan_id"] ?? 0));
          break;
        case 2: // Member Name
          filteredPayments.sort((a, b) {
            final aName = '${a["member_first_name"]} ${a["member_last_name"]}';
            final bName = '${b["member_first_name"]} ${b["member_last_name"]}';
            return ascending ? aName.compareTo(bName) : bName.compareTo(aName);
          });
          break;
        case 3: // Amount
          filteredPayments.sort((a, b) {
            final aAmt = (a["amount"] is num) ? (a["amount"] as num).toDouble() : 0.0;
            final bAmt = (b["amount"] is num) ? (b["amount"] as num).toDouble() : 0.0;
            return ascending ? aAmt.compareTo(bAmt) : bAmt.compareTo(aAmt);
          });
          break;
        case 4: // Type
          filteredPayments.sort((a, b) => ascending
              ? (a["payment_type"] ?? '').compareTo(b["payment_type"] ?? '')
              : (b["payment_type"] ?? '').compareTo(a["payment_type"] ?? ''));
          break;
        case 5: // Date
          filteredPayments.sort((a, b) {
            final aDate = DateTime.tryParse(a["payment_date"] ?? a["created_at"] ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b["payment_date"] ?? b["created_at"] ?? '') ?? DateTime(1970);
            return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          });
          break;
        case 6: // Status
          filteredPayments.sort((a, b) => ascending
              ? (a["status"] ?? '').compareTo(b["status"] ?? '')
              : (b["status"] ?? '').compareTo(a["status"] ?? ''));
          break;
      }
    });
  }

  // ===== UI WIDGETS =====

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildLoansSummaryCards() {
    return Row(
      children: [
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
                Text("Total Loans", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("$totalLoans"),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
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
                Text("Total Loan Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("₱${totalLoanAmount.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
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
                Text("Active Loans", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("$activeLoans"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsSummaryCards() {
    return Row(
      children: [
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
                Text("Total Payments", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("$totalPayments"),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
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
                Text("Total Amount Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("₱${totalPaymentAmount.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
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
                Text("Pending Validations", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("$pendingPayments"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoansFilters() {
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: TextField(
            controller: loanIdController,
            decoration: InputDecoration(
              labelText: "Loan ID",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (_) => _filterLoans(),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 160,
          height: buttonHeight,
          child: TextField(
            controller: memberNameController,
            decoration: InputDecoration(
              labelText: "Member Name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (_) => _filterLoans(),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: DropdownButtonFormField<String>(
            value: selectedLoanStatus,
            decoration: InputDecoration(
              labelText: "Status",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text("All")),
              DropdownMenuItem(value: "Active", child: Text("Active")),
              DropdownMenuItem(value: "Paid", child: Text("Paid")),
              DropdownMenuItem(value: "Overdue", child: Text("Overdue")),
            ],
            onChanged: (value) {
              setState(() {
                selectedLoanStatus = value;
                _filterLoans();
              });
            },
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _fetchLoans,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(80, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text("Refresh", style: TextStyle(color: Colors.white)),
          ),
        ),
        Spacer(),
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.download, color: Colors.white),
            label: Text("Download", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(100, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsFilters() {
    return Row(
      children: [
        SizedBox(
          width: 110,
          height: buttonHeight,
          child: TextField(
            controller: paymentIdController,
            decoration: InputDecoration(
              labelText: "Payment ID",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (_) => _filterPayments(),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 100,
          height: buttonHeight,
          child: TextField(
            controller: paymentLoanIdController,
            decoration: InputDecoration(
              labelText: "Loan ID",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (_) => _filterPayments(),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: DropdownButtonFormField<String>(
            value: selectedPaymentType,
            decoration: InputDecoration(
              labelText: "Type",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text("All")),
              DropdownMenuItem(value: "Cash", child: Text("Cash")),
              DropdownMenuItem(value: "Gcash", child: Text("GCash")),
              DropdownMenuItem(value: "Bank Transfer", child: Text("Bank")),
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentType = value;
                _filterPayments();
              });
            },
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 140,
          height: buttonHeight,
          child: DropdownButtonFormField<String>(
            value: selectedPaymentStatus,
            decoration: InputDecoration(
              labelText: "Status",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text("All")),
              DropdownMenuItem(value: "Pending Approval", child: Text("Pending")),
              DropdownMenuItem(value: "Validated", child: Text("Validated")),
              DropdownMenuItem(value: "Invalidated", child: Text("Invalidated")),
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentStatus = value;
                _filterPayments();
              });
            },
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _fetchPayments,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(80, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text("Refresh", style: TextStyle(color: Colors.white)),
          ),
        ),
        Spacer(),
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.download, color: Colors.white),
            label: Text("Download", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(100, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoansTable() {
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
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: loansSortColumnIndex,
              sortAscending: loansIsAscending,
              columns: [
                DataColumn(
                  label: Text("Loan ID", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
                DataColumn(
                  label: Text("Member Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
                DataColumn(
                  label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
                DataColumn(
                  label: Text("Repayment Term", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
                DataColumn(
                  label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
                DataColumn(
                  label: Text("Date Created", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortLoans(i, asc),
                ),
              ],
              rows: filteredLoans.map((loan) {
                final memberName = '${loan['member_first_name']} ${loan['member_last_name']}';
                final amount = (loan['loan_amount'] is num) 
                    ? (loan['loan_amount'] as num).toDouble() 
                    : 0.0;
                
                return DataRow(cells: [
                  DataCell(Text(loan['application_id'].toString())),
                  DataCell(Text(memberName)),
                  DataCell(Text('₱${amount.toStringAsFixed(2)}')),
                  DataCell(Text(loan['repayment_term'] ?? 'N/A')),
                  DataCell(Text(loan['status'] ?? 'N/A')),
                  DataCell(Text(_formatDate(loan['created_at']))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable() {
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
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: paymentsSortColumnIndex,
              sortAscending: paymentsIsAscending,
              columns: [
                DataColumn(
                  label: Text("Payment ID", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Loan ID", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Member Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
                DataColumn(
                  label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (i, asc) => _sortPayments(i, asc),
                ),
              ],
              rows: filteredPayments.map((payment) {
                final memberName = '${payment['member_first_name']} ${payment['member_last_name']}';
                final amount = (payment['amount'] is num) 
                    ? (payment['amount'] as num).toDouble() 
                    : 0.0;
                
                return DataRow(cells: [
                  DataCell(Text(payment['payment_id'].toString())),
                  DataCell(Text(payment['approved_loan_id'].toString())),
                  DataCell(Text(memberName)),
                  DataCell(Text('₱${amount.toStringAsFixed(2)}')),
                  DataCell(Text(payment['payment_type'] ?? 'N/A')),
                  DataCell(Text(_formatDate(payment['payment_date'] ?? payment['created_at']))),
                  DataCell(Text(payment['status'] ?? 'N/A')),
                ]);
              }).toList(),
            ),
          ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          "Loan & Payment Records",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "View all loans and payment records in the system.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 24),
                        
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue,
                            tabs: [
                              Tab(text: "Loans"),
                              Tab(text: "Payments"),
                            ],
                          ),
<<<<<<< HEAD:the_basics/lib/features/admin/admin_reports.dart
                          SizedBox(height: 24),

                          // buttons + filters row
                          buttonsAndFiltersRow(),

                          // table generated by filters
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

                              child: Form(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      
                                      // main table (sorting by time period not yet implemented)
                                      if (selectedReportType == "Active Loans")
                                        activeLoansTable(activeLoansData)
                                      else if (selectedReportType == "Overdue Loans")
                                        overdueLoansTable(overdueLoansData)
                                      else if (selectedReportType == "Member Loan Summary")
                                        memberLoansTable(memberLoansData)
                                      else if (selectedReportType == "Payment Collection")
                                        payCollectionTable(paymentCollectionData)
                                      else if (selectedReportType == "Missed Payments")
                                        missedPayTable(missedPaymentsData)
                                      else if (selectedReportType == "Voucher & Revenue Summary")
                                        voucherRevenueTable(voucherRevenueData)
                                      else
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.payment, size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'No Report Selected',
                                              style: TextStyle(fontSize: 18, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                    ]
                                  ),
                                ),
                              )

                            ),
=======
                        ),
                        SizedBox(height: 24),
                        
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // LOANS TAB
                              isLoadingLoans
                                  ? Center(child: CircularProgressIndicator())
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildLoansFilters(),
                                        SizedBox(height: 16),
                                        _buildLoansSummaryCards(),
                                        SizedBox(height: 16),
                                        _buildLoansTable(),
                                      ],
                                    ),
                              
                              // PAYMENTS TAB
                              isLoadingPayments
                                  ? Center(child: CircularProgressIndicator())
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildPaymentsFilters(),
                                        SizedBox(height: 16),
                                        _buildPaymentsSummaryCards(),
                                        SizedBox(height: 16),
                                        _buildPaymentsTable(),
                                      ],
                                    ),
                            ],
>>>>>>> 02803ea1429a5382c699040dad4b00ad21217999:the_basics/lib/features/admin/admin_records.dart
                          ),
                        ),
                      ],
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