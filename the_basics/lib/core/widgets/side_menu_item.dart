import 'package:flutter/material.dart';
import 'package:the_basics/core/utils/themes.dart';

class SideMenuItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String routeName;

  const SideMenuItem({
    super.key,
    required this.leading,
    required this.title,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final bool isSelected = currentRoute == routeName;

    final Color color = isSelected
        ? AppThemes.orange
        : AppThemes.sidenavOptions;

    return ListTile(
      leading: ColorFiltered(
        colorFilter: ColorFilter.mode(
          color,
          BlendMode.srcIn,
        ),
        child: leading,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pushReplacementNamed(context, routeName);
      },
    );
  }
}
