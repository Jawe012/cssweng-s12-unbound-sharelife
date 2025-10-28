import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';

class LoanReviewDetailsPage extends StatefulWidget {
  const LoanReviewDetailsPage({super.key});

  @override
  State<LoanReviewDetailsPage> createState() => _LoanReviewDetailsPageState();
}

class _LoanReviewDetailsPageState extends State<LoanReviewDetailsPage> {
  String decision = 'Approve';
  String reason1 = 'Missing Documents';
  String reason2 = 'Incomplete Requirements';
  final TextEditingController remarksController = TextEditingController();

  // for spacing
  double titleSpacing = 18;
  double textSpacing = 12;
  double dataSpacing = 100;
  double divSpacing = 100;

  // font sizes
  double titleFont = 20;
  double contentFont = 16;



  Widget loanInfo(double loanAmt, double annualInc, int installments,
                  String repayTerm, String busType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Loan Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Desired Loan Amount: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Annual Income: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Desired Installments: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Repayment Term: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Business Type: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₱$loanAmt', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('₱$annualInc', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$installments', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$repayTerm', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$busType', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget personalInfo(String fName, String lName, String dob, int age) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Borrower First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Borrower Last Name: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Date of Birth: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Age: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$fName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$lName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$dob', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$age', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget loanCoMakers(String spouseFName, String spouseLName,
                      String childFName, String childLName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Loan Co-makers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Spouse First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Spouse Last Name: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Children First Name/s: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Children Last Name: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$spouseFName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$spouseLName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$childFName', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$childLName', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget contactInfo(String email, String phone, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Contact Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Phone Number: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Home Address: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$email', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$phone', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$address', style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget decisionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text("Decision",
                style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: titleFont
              )),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Text("Decision:  "),
            SizedBox(width: titleSpacing),
            DropdownButton<String>(
              value: decision,
              items: [
                DropdownMenuItem(
                    value: "Approve",
                    child: Text("Approve")),
                DropdownMenuItem(
                    value: "Reject",
                    child: Text("Reject")),
              ],
              onChanged: (value) {
                setState(() {
                  decision = value!;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12),
        TextField(
          controller: remarksController,
          decoration: InputDecoration(
            labelText: "Remarks (optional)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Applicant will be notified via email upon approval or rejection.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buttonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Approve",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Reject",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const Spacer(),
      ],
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
                          Text(
                            "Loan Application Review",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Review applicant details and approve or reject this loan.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 30),


                          // back button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[350],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  "Back to Loan Reviews",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),


                          // main card
                          Expanded(
                            child: Container(
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
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    
                                    // Applicant info (static data for now)
                                    GridView(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 30,
                                        mainAxisSpacing: 30,
                                        mainAxisExtent: 230,
                                      ),
                                      children: [
                                        loanInfo(50000, 250000, 12, "Monthly", "Retail"),
                                        personalInfo("Mark Anthony", "Garcia", "January 1, 1970", 54),
                                        loanCoMakers("Mariel Ariel", "Garcia", "Miguel", "Garcia"),
                                        contactInfo("markanthony@email.com", "+63 917 123 4567", "Malate, Manila"),
                                      ],
                                    ),
                                    Divider(),


                                    // Decision Section
                                    decisionSection(),


                                    // Buttons
                                    buttonsRow(),
                                  ],
                                ),
                              ),
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