import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  String searchQuery = "";
  String selectedDateFilter = "All";

  // notifications shown in the list
  List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => notifications = []);
      return;
    }
    final userId = user.id;
    final userEmail = user.email;

    try {
      final memberResp = await client
          .from('members')
          .select('id, user_id, email_address')
          .or('user_id.eq.$userId,email_address.eq.$userEmail')
          .maybeSingle();

      int? memberId;
      if (memberResp != null) {
        final rawId = memberResp['id'];
        if (rawId is int) {
          memberId = rawId;
        } else {
          memberId = int.tryParse(rawId?.toString() ?? '');
        }
      }

      //building the notifications list
      final List notifs = [];

      // Query rejected loan applications
      final rejectedQuery = client.from('loan_application').select('application_id, member_id, reason, created_at');
      if (memberId != null) {
        // safe: compare int to int column
        rejectedQuery.eq('member_id', memberId);
      } else if (userEmail != null) {
        // fallback: compare email column (if present)
        rejectedQuery.eq('member_email', userEmail);
      }
      final rejectedResp = await rejectedQuery;

      // Query approved loans (table/columns may differ in your schema)
      final approvedQuery = client.from('approved_loans').select('application_id, member_id, created_at');
      if (memberId != null) {
        approvedQuery.eq('member_id', memberId);
      } else if (userEmail != null) {
        approvedQuery.eq('member_email', userEmail);
      }
      final approvedResp = await approvedQuery;

      final List<Map<String, String>> notifsList = [];

      // helper: parse various date representations into local DateTime
      DateTime _parseDateDynamic(dynamic value) {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (value is DateTime) return value.toLocal();
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
        final s = value.toString();
        final dt = DateTime.tryParse(s);
        if (dt != null) return dt.toLocal();
        final asInt = int.tryParse(s);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      // helper: format DateTime to 'Mon d, yyyy h:mm AM/PM'
      String _formatDateTime(DateTime dt) {
        if (dt.millisecondsSinceEpoch == 0) return '';
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final month = months[dt.month - 1];
        final day = dt.day;
        final year = dt.year;
        int hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        else if (hour > 12) hour -= 12;
        return '$month $day, $year $hour:$minute $period';
      }

      for (final row in approvedResp) {
          final loanId = (row['loan_id'] ?? row['application_id'] ?? '').toString();
          final rawDate = row['created_at'] ?? row['date_approved'] ?? '';
          final dt = _parseDateDynamic(rawDate);
          notifsList.add({
            "title": "Loan Approved",
            "body": "Your loan $loanId has been approved. Have a wonderful day!",
            "date": _formatDateTime(dt),
            "_ts": dt.millisecondsSinceEpoch.toString(),
          });
        }

      for (final row in rejectedResp) {
          final id = (row['application_id'] ?? row['id'] ?? '').toString();
          final rawDate = row['created_at'] ?? row['date_submitted'] ?? '';
          final reason = (row['reason'] ?? '').toString();
          final dt = _parseDateDynamic(rawDate);
          notifsList.add({
            "title": "Loan Rejected",
            "body": "Your loan application $id was rejected. Reason: $reason",
            "date": _formatDateTime(dt),
            "_ts": dt.millisecondsSinceEpoch.toString(),
          });
        }

      // sort using epoch stored in _ts (desc)
      notifsList.sort((a, b) {
        final aTs = int.tryParse(a['_ts'] ?? '') ?? 0;
        final bTs = int.tryParse(b['_ts'] ?? '') ?? 0;
        return bTs.compareTo(aTs);
      });

      setState(() => notifications = notifsList);

    } catch (e) {
      // On error, keep empty list but log
      print('Error loading notifications: $e');
      setState(() => notifications = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontSize: 26)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
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
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search notifications...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Date filter
                Row(
                  children: [
                    const Text("Date Filter: "),
                    DropdownButton<String>(
                      value: selectedDateFilter,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Today", child: Text("Today")),
                        DropdownMenuItem(value: "This Week", child: Text("This Week")),
                        DropdownMenuItem(value: "This Month", child: Text("This Month")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedDateFilter = value);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Notification List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: notifications.isEmpty
                    ? const Center(child: Text("No notifications"))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];

                          // Apply search filter
                          final title = notif["title"]!.toLowerCase();
                          final body = notif["body"]!.toLowerCase();
                          if (!title.contains(searchQuery.toLowerCase()) &&
                              !body.contains(searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
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
                                trailing: Text(notif["date"] ?? ""),
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