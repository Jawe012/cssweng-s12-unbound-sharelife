import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';

class EncoderReportsPage extends StatefulWidget {
  const EncoderReportsPage({super.key});

  @override
  State<EncoderReportsPage> createState() => EncoderReportsPageState();
}

class EncoderReportsPageState extends State<EncoderReportsPage> with SingleTickerProviderStateMixin {
  late TabController tabController;

  final List<String> reportTypes = [
    'Loan Reports',
    'Payment Reports',
    'Member Reports'
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: reportTypes.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(role: "Encoder"),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: TopNavBar(splash: "Encoder"),
      ),
      body: Row(
        children: [
          // Sidebar for desktop layout
          if (MediaQuery.of(context).size.width > 900)
            SizedBox(width: 250, child: SideMenu(role: "Encoder")),
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reports Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "View, filter, and generate reports for loans, payments, and member activities.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Tabs
                  TabBar(
                    controller: tabController,
                    labelColor: Colors.black,
                    indicatorColor: Colors.blueAccent,
                    tabs: reportTypes.map((r) => Tab(text: r)).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        buildLoanReports(),
                        buildPaymentReports(),
                        buildMemberReports(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoanReports() {
    return buildReportTable("Loan Reports");
  }

  Widget buildPaymentReports() {
    return buildReportTable("Payment Reports");
  }

  Widget buildMemberReports() {
    return buildReportTable("Member Reports");
  }

  Widget buildReportTable(String title) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: 'All',
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
              ],
              onChanged: (val) {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
              ],
              rows: List.generate(
                10,
                (index) => DataRow(cells: [
                  DataCell(Text('Member $index')),
                  DataCell(Text('₱${(index + 1) * 1000}')),
                  DataCell(Text('Oct ${index + 10}, 2025')),
                  DataCell(Text(index % 2 == 0 ? 'Approved' : 'Pending')),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}