import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';

class EncoderDashboard extends StatelessWidget {
  const EncoderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Column(
        children: [
          TopNavBar(splash: "Encoder"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SideMenu(role: "Encoder"),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Overview",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 24),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2,
                              children: [
                                SummaryCard(
                                  title: "Pending Applications", 
                                  desc: "Applications currently awaiting review, decision, or further action", 
                                  value: "123", 
                                  icon: Icons.pending_actions),
                                SummaryCard(
                                  title: "Pending Approval", 
                                  desc: "Encoded applications that are awaiting administrator approval", 
                                  value: "456", 
                                  icon: CupertinoIcons.hourglass),
                                SummaryCard(
                                  title: "Approved Applications", 
                                  desc: "Applications that have been reviewed and approved", 
                                  value: "101", 
                                  icon: Icons.check_circle),
                                SummaryCard(
                                  title: "Total Encoded Applications", 
                                  desc: "The total number of applications that have been encoded", 
                                  value: "789", 
                                  icon: Icons.checklist),
                              ],
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

class SummaryCard extends StatelessWidget {
  final String title;
  final String desc;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.desc,
    required this.value,
    this.icon = Icons.access_time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 200, color: CupertinoColors.placeholderText),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600), 
                    softWrap: true,
                    overflow: TextOverflow.visible),
                  SizedBox(height: 2),
                  Text(
                    desc, 
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                    softWrap: true,
                    overflow: TextOverflow.visible),
                  SizedBox(height: 8),
                  Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}