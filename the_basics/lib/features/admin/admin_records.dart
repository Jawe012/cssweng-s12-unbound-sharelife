import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/input_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRecords extends StatefulWidget {
  const AdminRecords({super.key});

  @override
  State<AdminRecords> createState() => _AdminRecordsState();
}

class _AdminRecordsState extends State<AdminRecords> {
  int? sortColumnIndex;
  bool isAscending = true;
  String? selectedReportType;

  // Temporary placeholder data
  final List<Map<String, dynamic>> activeLoansData = [];
  final List<Map<String, dynamic>> overdueLoansData = [];
  final List<Map<String, dynamic>> memberLoansData = [];
  final List<Map<String, dynamic>> paymentCollectionData = [];
  final List<Map<String, dynamic>> missedPaymentsData = [];
  final List<Map<String, dynamic>> voucherRevenueData = [];


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

        SizedBox(
          height: 28,
          child: ElevatedButton.icon(
            onPressed: () {},
            label: const Text(
              "Generate Report",
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
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 58,
                    columns: [
                      DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                      DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                      DataColumn(label: Text("Loan Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanType")),
                      DataColumn(label: Text("Principal Amount", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "principalAmt")),
                      DataColumn(label: Text("Remaining Balance", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "remainBal")),
                      DataColumn(label: Text("Start Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "startDate")),
                      DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["loanID"].toString())),
                        DataCell(Text(loan["memName"])),
                        DataCell(Text(loan["loanType"])),
                        DataCell(Text("₱${loan["principalAmt"]}")),
                        DataCell(Text("₱${loan["remainBal"]}")),
                        DataCell(Text(loan["startDate"])),
                        DataCell(Text(loan["dueDate"])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // loans with missed or late payments.
  Widget overdueLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
                      DataColumn(label: Text("Days Overdue", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "daysOverdue")),
                      DataColumn(label: Text("Amount Due", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amountDue")),
                      DataColumn(label: Text("Accumulated Late Fees", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "lateFees")),
                      DataColumn(label: Text("Contact No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "contactNo")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["loanID"].toString())),
                        DataCell(Text(loan["memName"])),
                        DataCell(Text(loan["loanType"])),
                        DataCell(Text(loan["dueDate"])),
                        DataCell(Text(loan["daysOverdue"].toString())),
                        DataCell(Text("₱${loan["amountDue"]}")),
                        DataCell(Text("₱${loan["lateFees"]}")),
                        DataCell(Text(loan["contactNo"])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // each member’s total loan activity.
  Widget memberLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 58,
                    columns: [
                      DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                      DataColumn(label: Text("Member ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memID")),
                      DataColumn(label: Text("Total Loans", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "totalLoans")),
                      DataColumn(label: Text("Total Borrowed", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "totalBorrowed")),
                      DataColumn(label: Text("Total Paid", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "totalPaid")),
                      DataColumn(label: Text("Outstanding Balance", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "outBal")),
                      DataColumn(label: Text("Last Payment Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "lastPaid")),
                      DataColumn(label: Text("Loan Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanStatus")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["memName"])),
                        DataCell(Text(loan["memID"].toString())),
                        DataCell(Text("₱${loan["totalLoans"]}")),
                        DataCell(Text("₱${loan["totalBorrowed"]}")),
                        DataCell(Text("₱${loan["totalPaid"]}")),
                        DataCell(Text("₱${loan["outBal"]}")),
                        DataCell(Text(loan["lastPaid"])),
                        DataCell(Text(loan["loanStatus"])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Track all payments received
  Widget payCollectionTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
                      DataColumn(label: Text("Amount Paid", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amountPaid")),
                      DataColumn(label: Text("Collected By", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "collectedBy")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["payID"])),
                        DataCell(Text(loan["memName"])),
                        DataCell(Text(loan["memID"])),
                        DataCell(Text(loan["loanID"])),
                        DataCell(Text(loan["payDate"])),
                        DataCell(Text(loan["payMethod"])),
                        DataCell(Text("₱${loan["amountPaid"]}")),
                        DataCell(Text(loan["collectedBy"])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Show scheduled payments that were not made on time.
  Widget missedPayTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 58,
                    columns: [
                      DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                      DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                      DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                      DataColumn(label: Text("Amount Due", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amountDue")),
                      DataColumn(label: Text("Days Missed", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "daysMissed")),
                      DataColumn(label: Text("Contact No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "contactNo")),
                      DataColumn(label: Text("Next Pay Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "nextPayDate")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["loanID"])),
                        DataCell(Text(loan["memName"])),
                        DataCell(Text(loan["dueDate"])),
                        DataCell(Text("₱${loan["amountDue"]}")),
                        DataCell(Text(loan["daysMissed"])),
                        DataCell(Text(loan["contactNo"])),
                        DataCell(Text(loan["nextPayDate"])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Show income from fees, interest, and voucher-based transactions.
  Widget voucherRevenueTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 58,
                    columns: [
                      DataColumn(label: Text("Voucher ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "voucherID")),
                      DataColumn(label: Text("Date Issued", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dateIssued")),
                      DataColumn(label: Text("Description", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "desc")),
                      DataColumn(label: Text("Amount Earned", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amtEarned")),
                      DataColumn(label: Text("Revenue Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "revType")),
                      DataColumn(label: Text("Recorded By", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "recordedBy")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["voucherID"])),
                        DataCell(Text(loan["dateIssued"])),
                        DataCell(Text(loan["desc"])),
                        DataCell(Text("₱${loan["amtEarned"]}")),
                        DataCell(Text(loan["revType"])),
                        DataCell(Text(loan["recordedBy"])),
                      ]);
                    }).toList(),
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
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Admin"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Admin"),

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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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