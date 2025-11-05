import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';

class EncoderReportsPage extends StatefulWidget {
  const EncoderReportsPage({super.key});

  @override
  State<EncoderReportsPage> createState() => _EncoderReportsPageState();
}

class _EncoderReportsPageState extends State<EncoderReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> reportTypes = [
    'Loan Reports',
    'Payment Reports',
    'Member Reports'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: reportTypes.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      indicatorColor: Colors.blueAccent,
                      tabs: reportTypes.map((r) => Tab(text: r)).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReportContainer(_buildLoanReports()),
                        _buildReportContainer(_buildPaymentReports()),
                        _buildReportContainer(_buildMemberReports()),
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

  Widget _buildReportContainer(Widget content) {
    return Container(
      width: double.infinity,
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
      child: content,
    );
  }

  Widget _buildLoanReports() {
    return _buildReportTable("Loan Reports");
  }

  Widget _buildPaymentReports() {
    return _buildReportTable("Payment Reports");
  }

  Widget _buildMemberReports() {
    return _buildReportTable("Member Reports");
  }

  Widget _buildReportTable(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters Row
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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

        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
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
