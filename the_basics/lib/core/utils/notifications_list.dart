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
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("Notifications", style: TextStyle(color: Colors.black, fontSize: 26)),
        iconTheme: IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
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
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: "Search notifications...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) => setState(() => searchQuery = value),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Date filter
                    Row(
                      children: [
                        Text("Date Filter: "),
                        DropdownButton<String>(
                          value: selectedDateFilter,
                          items: [
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
                  ],
                ),

            SizedBox(height: 10),

            // Notification List
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),

                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];

                    // Apply search filter
                    if (!notif["title"]!.toLowerCase().contains(searchQuery.toLowerCase()) &&
                        !notif["body"]!.toLowerCase().contains(searchQuery.toLowerCase())) {
                      return SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        ListTile(
                          title: Text(notif["title"]!),
                          subtitle: Text(
                            notif["body"]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(notif["date"]!),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/notification-view',
                              arguments: notif,
                            );
                          },
                        ),
                        Divider(height: 0.5, color: Colors.grey[300]),
                      ],
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
