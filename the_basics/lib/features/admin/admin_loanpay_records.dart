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


  // Loan tab things

  void onSortLoans(int columnIndex, bool ascending) {
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
              ? a["memName"].compareTo(b["memName"])
              : b["memName"].compareTo(a["memName"]));
          break;
        case 2:
          loans.sort((a, b) => ascending
              ? a["amt"].compareTo(b["amt"])
              : b["amt"].compareTo(a["amt"]));
          break;
        case 3:
          loans.sort((a, b) => ascending
              ? a["interest"].compareTo(b["interest"])
              : b["interest"].compareTo(a["interest"]));
          break;
        case 4:
          loans.sort((a, b) => ascending
              ? a["start"].compareTo(b["start"])
              : b["start"].compareTo(a["start"]));
          break;
        case 5:
          loans.sort((a, b) => ascending
              ? a["due"].compareTo(b["due"])
              : b["due"].compareTo(a["due"]));
          break;
        case 6:
          loans.sort((a, b) => ascending
              ? a["instType"].compareTo(b["instType"])
              : b["instType"].compareTo(a["instType"]));
          break;
        case 7:
          loans.sort((a, b) => ascending
              ? a["totalInst"].compareTo(b["totalInst"])
              : b["totalInst"].compareTo(a["totalInst"]));
          break;
        case 8:
          loans.sort((a, b) => ascending
              ? a["instAmt"].compareTo(b["instAmt"])
              : b["instAmt"].compareTo(a["instAmt"]));
          break;
        case 9:
          loans.sort((a, b) => ascending
              ? a["status"].compareTo(b["status"])
              : b["status"].compareTo(a["status"]));
          break;
      }
    });
  }

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

  Widget loansTable() {
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
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Member Name", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Interest", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Due Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Inst Type", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Total Inst", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Inst Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortLoans(i, asc)),
                      DataColumn(
                          label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortLoans(i, asc)),
                    ],
                    rows: loans
                        .map(
                          (loan) => DataRow(cells: [
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


  // Payment tab things
  void onSortPay(int columnIndex, bool ascending) {
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

  Widget payTable() {
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
                          label: Text("Payment ID", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Loan ID", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Inst. No.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Payment Type", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("GCash Ref No.", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Bank Name", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Pay Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                      DataColumn(
                          label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSortPay(i, asc)),
                    ],
                    rows: filteredPayments
                      .map((pay) => DataRow(cells: [
                        DataCell(Text("${pay["payment_id"] ?? ""}")),
                        DataCell(Text("${pay["approved_loan_id"] ?? ""}")),
                        DataCell(Text("${pay["installment_number"] ?? ""}")),
                        DataCell(Text("₱${pay["amount"] ?? 0}")),
                        DataCell(Text("${pay["payment_type"] ?? ""}")),
                        DataCell(Text("${pay["gcash_reference"] ?? ""}")),
                        DataCell(Text("${pay["bank_name"] ?? ""}")),
                        DataCell(Text("${pay["payment_date"] ?? ""}")),
                        DataCell(Text("${pay["status"] ?? ""}")),
                    ])).toList(),
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
                                      loansTable(),
                                    ],
                                  ),

                                  // ===== Payments Tab (placeholder) =====
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      payFilters(),
                                      SizedBox(height: 24),
                                      payTable(),
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