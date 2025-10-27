import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/data/loan_data.dart';

class MemberDB extends StatefulWidget {
  const MemberDB({super.key});

  @override
  State<MemberDB> createState() => _MemDBState();
}

class _MemDBState extends State<MemberDB> {
  int? sortColumnIndex;
  bool isAscending = true;
  List<Map<String, dynamic>> loans = loansData;
  double buttonHeight = 28;



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
                Text("₱60,000"),
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
                Text("₱40,000"),
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
                Text("₱100,000"),
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
          onPressed: () {},
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