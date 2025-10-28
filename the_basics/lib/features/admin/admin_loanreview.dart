import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/data/loan_data.dart';

class LoanReviewPage extends StatefulWidget {
  const LoanReviewPage({super.key});

  @override
  State<LoanReviewPage> createState() => _LoanReviewPageState();
}

class _LoanReviewPageState extends State<LoanReviewPage> {
  int? sortColumnIndex;
  bool isAscending = true;
  List<Map<String, dynamic>> loans = loansData;
  double buttonHeight = 28;




  Widget buildStatus(int number) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey,
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
                              buildStatus(5),
                            ],
                          ),

                          // filter row
                          SizedBox(height: 24),

                          // table
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.0),
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 1,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(label: Text("Applicant", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Loan Type", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Date Submitted", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: [
                                      _buildRow("Mark Reyes", "₱50,000",
                                          "Personal Loan", "Oct 20, 2025"),
                                      _buildRow("Jane Smith", "₱50,000", "Home Loan",
                                          "Oct 20, 2025"),
                                      _buildRow("Juan Dela Cruz", "₱50,000",
                                          "Personal Loan", "Oct 20, 2025"),
                                      _buildRow("Anne Mendoza", "₱50,000", "Home Loan",
                                          "Oct 20, 2025"),
                                      _buildRow("Randy Villanueva", "₱40,000",
                                          "Personal Loan", "Oct 20, 2025"),
                                      _buildRow("John Doe", "₱50,000", "Personal Loan",
                                          "Oct 21, 2025"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  DataRow _buildRow(String applicant, String amount, String type, String date) {
    return DataRow(cells: [
      DataCell(Text(applicant)),
      DataCell(Text(amount)),
      DataCell(Text(type)),
      DataCell(Text(date)),
      DataCell(ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: 
          Text(
            "Review",
            style: TextStyle(color: Colors.white)),
      )),
    ]);
  }
}