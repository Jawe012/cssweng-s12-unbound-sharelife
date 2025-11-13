import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EncoderReports extends StatefulWidget {
  const EncoderReports({super.key});

  @override
  State<EncoderReports> createState() => _EncoderReportsState();
}

class _EncoderReportsState extends State<EncoderReports> {
  int? sortColumnIndex;
  bool isAscending = true;
  String? selectedReportType;
  double buttonHeight = 28;
  bool _isLoading = false;

  // Real data from Supabase
  List<Map<String, dynamic>> _activeLoansData = [];
  List<Map<String, dynamic>> _overdueLoansData = [];
  List<Map<String, dynamic>> _memberLoansData = [];
  List<Map<String, dynamic>> _paymentCollectionData = [];
  List<Map<String, dynamic>> _voucherRevenueData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchActiveLoans(),
      _fetchOverdueLoans(),
      _fetchMemberLoanSummary(),
      _fetchPaymentCollections(),
      _fetchVoucherRevenue(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchActiveLoans() async {
    try {
      final response = await Supabase.instance.client
          .from('approved_loans')
          .select('*')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedLoans = [];
      
      for (var loan in response) {
        final memberId = loan['member_id'];
        String memberName = 'Unknown Member';
        
        if (memberId != null) {
          final memberResponse = await Supabase.instance.client
              .from('members')
              .select('first_name, last_name')
              .eq('member_id', memberId)
              .maybeSingle();
          
          if (memberResponse != null) {
            memberName = '${memberResponse['first_name']} ${memberResponse['last_name']}';
          }
        }

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
          'loanID': loanId,
          'memName': memberName,
          'loanType': loan['loan_type'] ?? 'Regular',
          'startDate': startDate.toString().split(' ')[0],
          'dueDate': dueDate.toString().split(' ')[0],
          'principalAmt': '₱${(loan['loan_amount'] ?? 0).toStringAsFixed(2)}',
          'remainBal': '₱${(loan['remaining_balance'] ?? loan['loan_amount'] ?? 0).toStringAsFixed(2)}',
        });
      }

      setState(() {
        _activeLoansData = fetchedLoans;
      });
    } catch (e) {
      print('Error fetching active loans: $e');
      setState(() {
        _activeLoansData = [];
      });
    }
  }

  Future<void> _fetchOverdueLoans() async {
    try {
      final response = await Supabase.instance.client
          .from('approved_loans')
          .select('*')
          .eq('status', 'overdue')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedLoans = [];
      
      for (var loan in response) {
        final memberId = loan['member_id'];
        String memberName = 'Unknown Member';
        String contactNo = 'N/A';
        
        if (memberId != null) {
          final memberResponse = await Supabase.instance.client
              .from('members')
              .select('first_name, last_name, contact_number')
              .eq('member_id', memberId)
              .maybeSingle();
          
          if (memberResponse != null) {
            memberName = '${memberResponse['first_name']} ${memberResponse['last_name']}';
            contactNo = memberResponse['contact_number'] ?? 'N/A';
          }
        }

        final createdAt = loan['created_at'] != null 
            ? DateTime.parse(loan['created_at']) 
            : DateTime.now();
        final year = createdAt.year;
        final loanId = 'LN-$year-${loan['application_id']?.toString().padLeft(4, '0') ?? '0000'}';

        final startDate = loan['created_at'] != null 
            ? DateTime.parse(loan['created_at']) 
            : DateTime.now();
        final dueDate = _calculateDueDate(startDate, loan['repayment_term']);
        final daysOverdue = DateTime.now().difference(dueDate).inDays;

        fetchedLoans.add({
          'loanID': loanId,
          'memName': memberName,
          'dueDate': dueDate.toString().split(' ')[0],
          'daysOverdue': daysOverdue > 0 ? daysOverdue : 0,
          'remainBal': '₱${(loan['remaining_balance'] ?? loan['loan_amount'] ?? 0).toStringAsFixed(2)}',
          'contactNo': contactNo,
        });
      }

      setState(() {
        _overdueLoansData = fetchedLoans;
      });
    } catch (e) {
      print('Error fetching overdue loans: $e');
      setState(() {
        _overdueLoansData = [];
      });
    }
  }

  Future<void> _fetchMemberLoanSummary() async {
    try {
      final response = await Supabase.instance.client
          .from('approved_loans')
          .select('*')
          .order('member_id', ascending: true);

      Map<String, Map<String, dynamic>> memberSummary = {};
      
      for (var loan in response) {
        final memberId = loan['member_id']?.toString() ?? 'unknown';
        
        if (!memberSummary.containsKey(memberId)) {
          String memberName = 'Unknown Member';
          
          if (loan['member_id'] != null) {
            final memberResponse = await Supabase.instance.client
                .from('members')
                .select('first_name, last_name')
                .eq('member_id', loan['member_id'])
                .maybeSingle();
            
            if (memberResponse != null) {
              memberName = '${memberResponse['first_name']} ${memberResponse['last_name']}';
            }
          }
          
          memberSummary[memberId] = {
            'memName': memberName,
            'totalLoans': 0,
            'totalBorrowed': 0.0,
            'totalPaid': 0.0,
            'remainBal': 0.0,
            'loanStatus': 'active',
          };
        }
        
        memberSummary[memberId]!['totalLoans'] += 1;
        memberSummary[memberId]!['totalBorrowed'] += (loan['loan_amount'] ?? 0);
        memberSummary[memberId]!['remainBal'] += (loan['remaining_balance'] ?? loan['loan_amount'] ?? 0);
        
        if (loan['status'] == 'overdue') {
          memberSummary[memberId]!['loanStatus'] = 'overdue';
        }
      }

      final List<Map<String, dynamic>> fetchedSummary = memberSummary.values.map((summary) {
        summary['totalPaid'] = summary['totalBorrowed'] - summary['remainBal'];
        return {
          'memName': summary['memName'],
          'totalLoans': summary['totalLoans'],
          'totalBorrowed': '₱${summary['totalBorrowed'].toStringAsFixed(2)}',
          'totalPaid': '₱${summary['totalPaid'].toStringAsFixed(2)}',
          'remainBal': '₱${summary['remainBal'].toStringAsFixed(2)}',
          'loanStatus': summary['loanStatus'],
        };
      }).toList();

      setState(() {
        _memberLoansData = fetchedSummary;
      });
    } catch (e) {
      print('Error fetching member loan summary: $e');
      setState(() {
        _memberLoansData = [];
      });
    }
  }

  Future<void> _fetchPaymentCollections() async {
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select('*')
          .order('payment_date', ascending: false);

      final List<Map<String, dynamic>> fetchedPayments = [];
      
      for (var payment in response) {
        final loanId = payment['loan_id'];
        String loanRef = 'Unknown';
        
        if (loanId != null) {
          final loanResponse = await Supabase.instance.client
              .from('approved_loans')
              .select('application_id, created_at')
              .eq('loan_id', loanId)
              .maybeSingle();
          
          if (loanResponse != null) {
            final createdAt = loanResponse['created_at'] != null 
                ? DateTime.parse(loanResponse['created_at']) 
                : DateTime.now();
            final year = createdAt.year;
            loanRef = 'LN-$year-${loanResponse['application_id']?.toString().padLeft(4, '0') ?? '0000'}';
          }
        }

        String collectedBy = 'Unknown';
        final staffId = payment['staff_id'];
        if (staffId != null) {
          final staffResponse = await Supabase.instance.client
              .from('staff')
              .select('first_name, last_name')
              .eq('staff_id', staffId)
              .maybeSingle();
          
          if (staffResponse != null) {
            collectedBy = '${staffResponse['first_name']} ${staffResponse['last_name']}';
          }
        }

        fetchedPayments.add({
          'paymentID': payment['payment_id']?.toString() ?? 'N/A',
          'loanRef': loanRef,
          'amtPaid': '₱${(payment['amount'] ?? 0).toStringAsFixed(2)}',
          'paymentDate': payment['payment_date'] ?? 'N/A',
          'payMethod': payment['payment_method'] ?? 'N/A',
          'collectedBy': collectedBy,
        });
      }

      setState(() {
        _paymentCollectionData = fetchedPayments;
      });
    } catch (e) {
      print('Error fetching payment collections: $e');
      setState(() {
        _paymentCollectionData = [];
      });
    }
  }

  Future<void> _fetchVoucherRevenue() async {
    try {
      final loansResponse = await Supabase.instance.client
          .from('approved_loans')
          .select('*');

      final paymentsResponse = await Supabase.instance.client
          .from('payments')
          .select('*');

      double totalDisbursed = 0;
      double totalPaid = 0;
      double totalOverdue = 0;

      for (var loan in loansResponse) {
        totalDisbursed += (loan['loan_amount'] ?? 0);
        
        if (loan['status'] == 'overdue') {
          totalOverdue += (loan['remaining_balance'] ?? loan['loan_amount'] ?? 0);
        }
      }

      for (var payment in paymentsResponse) {
        totalPaid += (payment['amount'] ?? 0);
      }

      final outstanding = totalDisbursed - totalPaid;

      setState(() {
        _voucherRevenueData = [
          {
            'metric': 'Total Disbursed',
            'value': '₱${totalDisbursed.toStringAsFixed(2)}',
          },
          {
            'metric': 'Total Paid',
            'value': '₱${totalPaid.toStringAsFixed(2)}',
          },
          {
            'metric': 'Outstanding Balance',
            'value': '₱${outstanding.toStringAsFixed(2)}',
          },
          {
            'metric': 'Overdue Amount',
            'value': '₱${totalOverdue.toStringAsFixed(2)}',
          },
        ];
      });
    } catch (e) {
      print('Error fetching voucher revenue: $e');
      setState(() {
        _voucherRevenueData = [];
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

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonsAndFiltersRow() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: DropdownInputField(
            label: "Report Type",
            items: [
              "Active Loans",
              "Overdue Loans",
              "Member Loan Summary",
              "Payment Collection",
              "Missed Payments",
              "Voucher & Revenue Summary"
            ],
            onChanged: (value) {
              setState(() {
                selectedReportType = value;
              });
            },
          ),
        ),
        SizedBox(width: 16),

        SizedBox(
          width: 250,
          child: DropdownInputField(
            label: "Filter by...",
            items: [
              "Month",
              "Quarter",
              "Year",
            ],
          ),
        ),
        SizedBox(width: 16),

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
      ],
    );
  }

  void onSort<T>(
    int columnIndex,
    bool ascending,
    List<Map<String, dynamic>> data,
    String key,
  ) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      data.sort((a, b) {
        final valueA = a[key];
        final valueB = b[key];

        if (valueA == null || valueB == null) return 0;

        if (valueA is num && valueB is num) {
          return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
        } else if (valueA is DateTime && valueB is DateTime) {
          return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
        } else {
          return ascending
              ? valueA.toString().compareTo(valueB.toString())
              : valueB.toString().compareTo(valueA.toString());
        }
      });
    });
  }

  // all loans currently being paid (not yet completed or overdue).
  Widget activeLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Loan Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanType")),
                    DataColumn(label: Text("Start Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "startDate")),
                    DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    DataColumn(label: Text("Principal Amount", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "principalAmt")),
                    DataColumn(label: Text("Remaining Balance", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "remainBal")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                    DataCell(Text("${loan["loanID"] ?? "-"}")),
                    DataCell(Text("${loan["memName"] ?? "-"}")),
                    DataCell(Text("${loan["loanType"] ?? "-"}")),
                    DataCell(Text("${loan["startDate"] ?? "-"}")),
                    DataCell(Text("${loan["dueDate"] ?? "-"}")),
                    DataCell(Text("₱${loan["principalAmt"] ?? "0"}")),
                    DataCell(Text("₱${loan["remainBal"] ?? "0"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // loans with missed or late payments.
  Widget overdueLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Loan Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanType")),
                    DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    DataColumn(label: Text("Days Overdue", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "daysOverdue")),
                    DataColumn(label: Text("Amount Due", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amountDue")),
                    DataColumn(label: Text("Accumulated Late Fees", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "lateFees")),
                    DataColumn(label: Text("Contact No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "contactNo")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["loanID"] ?? "-"}")),
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["loanType"] ?? "-"}")),
                      DataCell(Text("${loan["dueDate"] ?? "-"}")),
                      DataCell(Text("${loan["daysOverdue"] ?? "0"}")),
                      DataCell(Text("₱${loan["amountDue"] ?? "0"}")),
                      DataCell(Text("₱${loan["lateFees"] ?? "0"}")),
                      DataCell(Text("${loan["contactNo"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // each member’s total loan activity.
  Widget memberLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Member ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memID")),
                    DataColumn(label: Text("Total Loans", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalLoans")),
                    DataColumn(label: Text("Total Borrowed", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalBorrowed")),
                    DataColumn(label: Text("Total Paid", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalPaid")),
                    DataColumn(label: Text("Outstanding Balance", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "outBal")),
                    DataColumn(label: Text("Last Payment Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "lastPaid")),
                    DataColumn(label: Text("Loan Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanStatus")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["memID"] ?? "-"}")),
                      DataCell(Text("${loan["totalLoans"] ?? "0"}")),
                      DataCell(Text("₱${loan["totalBorrowed"] ?? "0"}")),
                      DataCell(Text("₱${loan["totalPaid"] ?? "0"}")),
                      DataCell(Text("₱${loan["outBal"] ?? "0"}")),
                      DataCell(Text("${loan["lastPaid"] ?? "-"}")),
                      DataCell(Text("${loan["loanStatus"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Track all payments received
  Widget payCollectionTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Payment ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Member ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memID")),
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Payment Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payDate")),
                    DataColumn(label: Text("Payment Method", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payMethod")),
                    DataColumn(label: Text("Amount Paid", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amountPaid")),
                    DataColumn(label: Text("Collected By", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "collectedBy")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["payID"] ?? "-"}")),
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["memID"] ?? "-"}")),
                      DataCell(Text("${loan["loanID"] ?? "-"}")),
                      DataCell(Text("${loan["payDate"] ?? "-"}")),
                      DataCell(Text("${loan["payMethod"] ?? "-"}")),
                      DataCell(Text("₱${loan["amountPaid"] ?? "0"}")),
                      DataCell(Text("${loan["collectedBy"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Show scheduled payments that were not made on time.
  Widget missedPayTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    DataColumn(label: Text("Amount Due", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amountDue")),
                    DataColumn(label: Text("Days Missed", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "daysMissed")),
                    DataColumn(label: Text("Contact No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "contactNo")),
                    DataColumn(label: Text("Next Pay Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "nextPayDate")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["loanID"] ?? "-"}")),
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["dueDate"] ?? "-"}")),
                      DataCell(Text("₱${loan["amountDue"] ?? "0"}")),
                      DataCell(Text("${loan["daysMissed"] ?? "0"}")),
                      DataCell(Text("${loan["contactNo"] ?? "-"}")),
                      DataCell(Text("${loan["nextPayDate"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Show income from fees, interest, and voucher-based transactions.
  Widget voucherRevenueTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Voucher ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "voucherID")),
                    DataColumn(label: Text("Date Issued", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dateIssued")),
                    DataColumn(label: Text("Description", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "desc")),
                    DataColumn(label: Text("Amount Earned", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amtEarned")),
                    DataColumn(label: Text("Revenue Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "revType")),
                    DataColumn(label: Text("Recorded By", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "recordedBy")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["voucherID"] ?? "-"}")),
                      DataCell(Text("${loan["dateIssued"] ?? "-"}")),
                      DataCell(Text("${loan["desc"] ?? "-"}")),
                      DataCell(Text("₱${loan["amtEarned"] ?? "0"}")),
                      DataCell(Text("${loan["revType"] ?? "-"}")),
                      DataCell(Text("${loan["recordedBy"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
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

          // main area
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
                            "Reports Dashboard",
                            style: TextStyle(fontSize: 28, 
                            fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Review various types of reports.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
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
                                        _activeLoansData.isEmpty 
                                          ? _emptyState('No active loans found')
                                          : activeLoansTable(_activeLoansData)
                                      else if (selectedReportType == "Overdue Loans")
                                        _overdueLoansData.isEmpty 
                                          ? _emptyState('No overdue loans found')
                                          : overdueLoansTable(_overdueLoansData)
                                      else if (selectedReportType == "Member Loan Summary")
                                        _memberLoansData.isEmpty 
                                          ? _emptyState('No member loan data found')
                                          : memberLoansTable(_memberLoansData)
                                      else if (selectedReportType == "Payment Collection")
                                        _paymentCollectionData.isEmpty 
                                          ? _emptyState('No payment collections found')
                                          : payCollectionTable(_paymentCollectionData)
                                      else if (selectedReportType == "Missed Payments")
                                        _emptyState('Missed payments feature coming soon')
                                      else if (selectedReportType == "Voucher & Revenue Summary")
                                        _voucherRevenueData.isEmpty 
                                          ? _emptyState('No revenue data found')
                                          : voucherRevenueTable(_voucherRevenueData)
                                      else
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(CupertinoIcons.chart_bar_alt_fill, size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'No Report Selected',
                                              style: TextStyle(fontSize: 18, color: Colors.grey),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Reports will appear here once you have chosen a report',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                    ]
                                  ),
                                ),
                              )

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