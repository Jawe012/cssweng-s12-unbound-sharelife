import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SideMenu extends StatelessWidget {
  final String role; // member, admin, encoder

  const SideMenu({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero
        ),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: _buildMenuItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    switch (role) {
      case "Settings":
        return [
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Personal Info"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/profile-page');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Account Settings"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/account-options');
            },
          ),
        ];

      case "Admin":
        return [
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Staff Management"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-dash');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: const Text("Loan Application Review"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-loanreview');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Image.asset(
                    'assets/icons/php-icon.png',
                    width: 20,
                    height: 20,
                  ),
            title: const Text("Payment Form Review"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-payment-review');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.receipt_long_sharp),
            title: const Text("Voucher Search & Generation"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-finance');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Reports Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-reports');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text("Loan and Payment Records"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-loanpay-rec');
            },
          ),
        ];

      case "Encoder":
        return [
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.query_stats),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/encoder-dash');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(CupertinoIcons.pencil),
            title: const Text("Encode Loan Applications"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/encoder-appliform');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Image.asset(
                    'assets/icons/php-icon.png',
                    width: 20,
                    height: 20,
                  ),
            title: const Text("Encode Payment Forms"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/encoder-payment');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Reports Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/encoder-report');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text("Loan and Payment Records"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/encoder-loanpay-rec');
            },
          ),
        ];

      case "Member":
      default:
        return [
          SizedBox(height: 10),
          ListTile(
            leading: Image.asset(
                    'assets/icons/loan_icon.png',
                    width: 24,
                    height: 24,
                  ),
            title: const Text("My Loans"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/member-dash');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("My Payments"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/member-payment-history');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(CupertinoIcons.pencil),
            title: const Text("Apply for Loan"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/member-appliform');
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Image.asset(
                    'assets/icons/php-icon.png',
                    width: 20,
                    height: 20,
                  ),
            title: const Text("Pay for Loan"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/member-payment');
            },
          ),
        ];
    }
  }
}
