import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/data/loan_data.dart';
import 'package:the_basics/data/pay_data.dart';

class AdminLoanPayRec extends StatefulWidget {
  const AdminLoanPayRec({super.key});

  @override
  State<AdminLoanPayRec> createState() => _MemDBState();
}

class _MemDBState extends State<AdminLoanPayRec> {
  int? sortColumnIndex;
  bool isAscending = true;

  // placeholder data
  List<Map<String, dynamic>> loans = loansData;
  List<Map<String, dynamic>> filteredPayments = payData;
    List<Map<String, dynamic>> payments = payData;

  double buttonHeight = 28;

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

  // Loan tab things

  Widget loanFilters() {
    return Container(
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
      child: Row(
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
                setState(() {
                  loans = loansData
                      .where((loan) =>
                          loan["ref"].toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),
          SizedBox(width: 16),

          // Member name search
          SizedBox(
            width: 160,
            height: buttonHeight,
            child: TextField(
              decoration: InputDecoration(
                labelText: "Member Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) {
                setState(() {
                  loans = loansData
                      .where((loan) =>
                          loan["memName"].toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
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

          // refresh button
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {}, //_fetchPaymentHistory,
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

          // Download button
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                "Download",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(100, buttonHeight),
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loansTable(List<Map<String, dynamic>> loans) {
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
                      DataColumn(label: Text("Ref No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "ref")),
                      DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                      DataColumn(label: Text("Amt.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amt")),
                      DataColumn(label: Text("Interest", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "interest")),
                      DataColumn(label: Text("Start Date", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "start")),
                      DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "due")),
                      DataColumn(label: Text("Inst. Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "instType")),
                      DataColumn(label: Text("Total Inst.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalInst")),
                      DataColumn(label: Text("Inst. Amt.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "instAmt")),
                      DataColumn(label: Text("Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "status")),
                    ],
                    rows: loans.map((loan) {
                      return DataRow(cells: [
                        DataCell(Text(loan["ref"])),
                        DataCell(Text(loan["memName"])),
                        DataCell(Text("₱${loan["amt"]}")),
                        DataCell(Text("${loan["interest"]}%")),
                        DataCell(Text(loan["start"])),
                        DataCell(Text(loan["due"])),
                        DataCell(Text(loan["instType"])),
                        DataCell(Text("${loan["totalInst"]}")),
                        DataCell(Text("₱${loan["instAmt"]}")),
                        DataCell(Text(loan["status"])),
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


  // Payment tab things

  Widget payFilters() {
    return Container(
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
      child: Row(
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
              onPressed: () {}, //_fetchPaymentHistory,
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
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () {
              },
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                "Download",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(100, buttonHeight),
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget payTable(List<Map<String, dynamic>> loans) {
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
                      DataColumn(label: Text("Payment ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_id")),
                      DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "approved_loan_id")),
                      DataColumn(label: Text("Inst. No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "installment_number")),
                      DataColumn(label: Text("Amt.", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amount")),
                      DataColumn(label: Text("Payment Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_type")),
                      DataColumn(label: Text("GCash Ref No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "gcash_reference")),
                      DataColumn(label: Text("Bank Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "bank_name")),
                      DataColumn(label: Text("Pay Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_date")),
                      DataColumn(label: Text("Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "status")),
                    ],
                    rows: filteredPayments.map((pay) {
                      return DataRow(cells: [
                        DataCell(Text("${pay["payment_id"] ?? ""}")),
                        DataCell(Text("${pay["approved_loan_id"] ?? ""}")),
                        DataCell(Text("${pay["installment_number"] ?? ""}")),
                        DataCell(Text("₱${pay["amount"] ?? 0}")),
                        DataCell(Text("${pay["payment_type"] ?? ""}")),
                        DataCell(Text("${pay["gcash_reference"] ?? ""}")),
                        DataCell(Text("${pay["bank_name"] ?? ""}")),
                        DataCell(Text("${pay["payment_date"] ?? ""}")),
                        DataCell(Text("${pay["status"] ?? ""}")),
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
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // title
                            Text(
                              "Loan & Payment Records",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "View and filter through all loan and payment records here.",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            SizedBox(height: 24),

                            // tabs
                            TabBar(
                              labelColor: Colors.black,
                              indicatorColor: Colors.black,
                              tabs: [
                                Tab(text: "Loans"),
                                Tab(text: "Payments"),
                              ],
                            ),
                            SizedBox(height: 16),

                            // tab content
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // ===== Loans Tab =====
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      loanFilters(),
                                      SizedBox(height: 24),
                                      loansTable(loans),
                                    ],
                                  ),

                                  // ===== Payments Tab (placeholder) =====
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      payFilters(),
                                      SizedBox(height: 24),
                                      payTable(filteredPayments),
                                    ],
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