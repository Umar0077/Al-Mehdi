import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../constants/colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int)? onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFFe5faf3),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.home,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () {
              onItemSelected?.call(0);
            },
          ),
          const SizedBox(height: 3),
          _SidebarItem(
            icon: Iconsax.teacher,
            label: 'Classes',
            selected: selectedIndex == 1,
            onTap: () {
              onItemSelected?.call(1);
            },
          ),
          const SizedBox(height: 3),
          _SidebarItem(
            icon: Icons.bar_chart,
            label: 'Attendance',
            selected: selectedIndex == 2,
            onTap: () {
              onItemSelected?.call(2);
            },
          ),
          const SizedBox(height: 3),
          _SidebarItem(
            icon: Icons.chat,
            label: 'Chat',
            selected: selectedIndex == 3,
            onTap: () {
              onItemSelected?.call(3);
            },
          ),
          const SizedBox(height: 3),
          _SidebarItem(
            icon: Icons.settings,
            label: 'Settings',
            selected: selectedIndex == 4,
            onTap: () {
              onItemSelected?.call(4);
            },
          ),
          const SizedBox(height: 3),
          _SidebarItem(
            icon: Iconsax.user,
            label: 'Profile',
            selected: selectedIndex == 5,
            onTap: () {
              onItemSelected?.call(5);
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? appGreen : Colors.black),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: selected ? appGreen : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
