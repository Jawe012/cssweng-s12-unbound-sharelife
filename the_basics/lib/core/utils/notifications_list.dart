import 'package:flutter/material.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  String searchQuery = "";
  String selectedDateFilter = "All";

  final List<Map<String, String>> notifications = [
    {
      "title": "Loan Application Update",
      "body": "Your loan has been approved.",
      "date": "2025-02-11"
    },
    {
      "title": "Payment Reminder",
      "body": "Your next payment is due on Feb 20.",
      "date": "2025-02-10"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Notifications", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ SEARCH BAR
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search notifications...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),

            const SizedBox(height: 16),

            // ✅ DATE FILTER DROPDOWN
            Row(
              children: [
                const Text("Date Filter:  "),
                DropdownButton<String>(
                  value: selectedDateFilter,
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                    DropdownMenuItem(value: "Today", child: Text("Today")),
                    DropdownMenuItem(value: "This Week", child: Text("This Week")),
                    DropdownMenuItem(value: "This Month", child: Text("This Month")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedDateFilter = value!);
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ NOTIFICATION LIST
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];

                    // ✅ Apply search filter
                    if (!notif["title"]!.toLowerCase().contains(searchQuery.toLowerCase()) &&
                        !notif["body"]!.toLowerCase().contains(searchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      title: Text(notif["title"]!),
                      subtitle: Text(notif["body"]!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(notif["date"]!),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/notification-view',
                          arguments: notif,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
