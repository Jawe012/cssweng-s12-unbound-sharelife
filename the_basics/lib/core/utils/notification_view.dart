import 'package:flutter/material.dart';

class NotificationViewPage extends StatelessWidget {
  const NotificationViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        title: Text("Notifications", style: TextStyle(color: Colors.black, fontSize: 26)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),

      body: Center(
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
          width: double.infinity,
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              
              Text(
                notif["title"]!,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),

              Divider(height: 0.5, color: Colors.grey[300]),

              Text(
                notif["date"]!,
                style: TextStyle(color: Colors.grey),
              ),
              
              SizedBox(height: 20),

              Text(
                notif["body"]!,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
