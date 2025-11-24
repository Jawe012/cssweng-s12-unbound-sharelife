import 'package:flutter/material.dart';
import 'package:the_basics/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class TopNavBar extends StatefulWidget {
  final String splash;
  final bool logoIsBackButton;
  final VoidCallback? onLogoBack;
  final VoidCallback? onAccountSettings;

  const TopNavBar({
    super.key,
    required this.splash,
    this.logoIsBackButton = false,
    this.onLogoBack,
    this.onAccountSettings,
  });


  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {

  // get auth service
  final authService = AuthService();

  // logout button pressed
  void logOut() async {
    await authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
  color: AppThemes.topnavContainer,
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 0,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ],
  border: Border(
    bottom: BorderSide(
      color: AppThemes.lines,
      width: 0.5,
    ),
  ),
),
      child: Row(
        children: [
          SideMenuBtn(
            splash: widget.splash,
            logoIsBackButton: widget.logoIsBackButton,
            onLogoBack: widget.onLogoBack,
          ),
          Spacer(),
          MenuOptions(),
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(Icons.notifications_outlined, size: 28, color: AppThemes.topnavIcons),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          SizedBox(width: 10),
          ProfileBtn(onAccountSettings: widget.onAccountSettings),
        ],
      ),
    );
  }
}

class SideMenuBtn extends StatelessWidget {
  final String splash;
  final bool logoIsBackButton;
  final VoidCallback? onLogoBack;

  const SideMenuBtn({
    super.key,
    required this.splash,
    this.logoIsBackButton = false,
    this.onLogoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          // logo (can act as back button if enabled)
          icon: Image.asset(
            'assets/icons/logo.png',
            height: 40,
            width: 40,
          ),
          onPressed: () {
            if (logoIsBackButton) {
              if (onLogoBack != null) {
                onLogoBack!();
              } else {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              }
            } else {
              Scaffold.of(context).openDrawer();  // opens sidebar (dunno if i shld keep this pa)
            }
          },
        ),

        SizedBox(width: 8),

        // org name + role
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Sharelife Consumers Cooperative",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppThemes.topnavName,
              ),
            ),
            Text(
              splash,  // Display the splash value
              style: TextStyle(
                fontSize: 14,
                color: AppThemes.topnavRole,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class MenuOptions extends StatelessWidget {
  const MenuOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ProfileBtn extends StatefulWidget {
  final bool accountSettingsRoute;
  final VoidCallback? onAccountSettings;

  const ProfileBtn({
    super.key,
    this.accountSettingsRoute = true,
    this.onAccountSettings,
  });

  @override
  State<ProfileBtn> createState() => _ProfileBtnState();
}

class _ProfileBtnState extends State<ProfileBtn> {
  // get auth service
  final authService = AuthService();

  // logout button
  void logout() async {
    await authService.signOut();
    //Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Get user initials from first and last name
  Future<String> _getUserInitials() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'U';

      // Try members table first
      var userRecord = await Supabase.instance.client
          .from('members')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();

      // If not in members, try staff
      if (userRecord == null) {
        final email = Supabase.instance.client.auth.currentUser?.email;
        if (email != null) {
          userRecord = await Supabase.instance.client
              .from('staff')
              .select('first_name, last_name')
              .eq('email_address', email)
              .maybeSingle();
        }
      }

      if (userRecord != null) {
        final firstName = (userRecord['first_name'] ?? '').toString();
        final lastName = (userRecord['last_name'] ?? '').toString();
        
        final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
        final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
        
        return firstInitial + lastInitial;
      }
    } catch (e) {
      debugPrint('Error fetching user initials: $e');
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            if (widget.onAccountSettings != null) {
              widget.onAccountSettings!();
            } else if (widget.accountSettingsRoute) {
              Navigator.pushNamed(context, '/profile-page');
            }
          },
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Center(
            child: Text("Profile Settings"),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          onTap: () { logout(); },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
      child: FutureBuilder<String>(
        future: _getUserInitials(),
        builder: (context, snapshot) {
          final initials = snapshot.data ?? 'U';
          return CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Text(
              initials,
              style: const TextStyle(color: Color(0xFF0C0C0D), fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}