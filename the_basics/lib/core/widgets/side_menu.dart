import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'package:the_basics/core/widgets/side_menu_item.dart';

class SideMenu extends StatelessWidget {
  final String role; // member, admin, encoder

  const SideMenu({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: AppThemes.sidenavContainer,
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

      // ================= SETTINGS =================
      case "Settings":
        return [
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.person),
            title: "Personal Info",
            routeName: '/profile-page',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.settings),
            title: "Account Settings",
            routeName: '/account-options',
          ),
        ];

      // ================= ADMIN =================
      case "Admin":
        return [
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.people),
            title: "Staff Management",
            routeName: '/admin-dash',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.checklist_rtl),
            title: "Loan Application Review",
            routeName: '/admin-loanreview',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: ImageIcon(AssetImage('assets/icons/php-icon.png')),
            title: "Payment Form Review",
            routeName: '/admin-payment-review',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.receipt_long_sharp),
            title: "Voucher Search & Generation",
            routeName: '/admin-finance',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.bar_chart),
            title: "Reports Dashboard",
            routeName: '/admin-reports',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.folder),
            title: "Loan and Payment Records",
            routeName: '/admin-loanpay-rec',
          ),
        ];

      // ================= ENCODER =================
      case "Encoder":
        return [
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.query_stats),
            title: "Dashboard",
            routeName: '/encoder-dash',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(CupertinoIcons.pencil),
            title: "Encode Loan Applications",
            routeName: '/encoder-appliform',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: ImageIcon(AssetImage('assets/icons/php-icon.png')),
            title: "Encode Payment Forms",
            routeName: '/encoder-payment',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.bar_chart),
            title: "Reports Dashboard",
            routeName: '/encoder-report',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.folder),
            title: "Loan and Payment Records",
            routeName: '/encoder-loanpay-rec',
          ),
        ];

      // ================= MEMBER =================
      case "Member":
      default:
        return [
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: ImageIcon(AssetImage('assets/icons/loan_icon.png')),
            title: "My Loans",
            routeName: '/member-dash',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(Icons.receipt_long),
            title: "My Payments",
            routeName: '/member-payment-history',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: Icon(CupertinoIcons.pencil),
            title: "Apply for Loan",
            routeName: '/member-appliform',
          ),
          const SizedBox(height: 10),
          const SideMenuItem(
            leading: ImageIcon(AssetImage('assets/icons/php-icon.png')),
            title: "Pay for Loan",
            routeName: '/member-payment',
          ),
        ];
    }
  }
}