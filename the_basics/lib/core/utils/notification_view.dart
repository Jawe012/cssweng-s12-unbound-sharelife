import 'package:flutter/material.dart';

class NotificationViewPage extends StatelessWidget {
  const NotificationViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text("Notification"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif["title"]!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                notif["date"]!,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Text(
                notif["body"]!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
