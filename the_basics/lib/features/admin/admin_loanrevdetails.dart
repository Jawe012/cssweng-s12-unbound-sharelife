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
                            "Loan Application Review",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Review applicant details and approve or reject this loan.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Applicant info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Applicant",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("Mark Reyes"),
                                            SizedBox(height: 12),
                                            Text("Email",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("mark@school.edu"),
                                            SizedBox(height: 12),
                                            Text("Member Type",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("Regular"),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Loan Type",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("Personal Loan"),
                                            SizedBox(height: 12),
                                            Text("Amount Requested",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("₱50,000"),
                                            SizedBox(height: 12),
                                            Text("Payment Term",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            Text("12 months"),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    const Divider(),

                                    // Decision Section
                                    const Text("Decision",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        const Text("Decision:  "),
                                        const SizedBox(width: 10),
                                        DropdownButton<String>(
                                          value: decision,
                                          items: const [
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

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        DropdownButton<String>(
                                          value: reason1,
                                          items: const [
                                            DropdownMenuItem(
                                                value: "Missing Documents",
                                                child: Text("Missing Documents")),
                                            DropdownMenuItem(
                                                value: "Invalid Information",
                                                child: Text("Invalid Information")),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              reason1 = value!;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 20),
                                        DropdownButton<String>(
                                          value: reason2,
                                          items: const [
                                            DropdownMenuItem(
                                                value: "Incomplete Requirements",
                                                child: Text("Incomplete Requirements")),
                                            DropdownMenuItem(
                                                value: "Other", child: Text("Other")),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              reason2 = value!;
                                            });
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

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

                                    const SizedBox(height: 10),
                                    const Text(
                                      "Applicant will be notified via email upon approval or rejection.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 20),

                                    // Buttons
                                    Row(
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
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Back to List"),
                                        ),
                                      ],
                                    ),
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