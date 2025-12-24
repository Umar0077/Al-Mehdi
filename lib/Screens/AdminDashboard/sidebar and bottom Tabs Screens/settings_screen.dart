import 'admin_settings_mobile.dart';
import 'admin_settings_web.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (width >= 900) {
          // Desktop Layout
          return const AdminSettingsScreenWeb();
        } else {
          // Mobile Layout
          return const AdminSettingsScreenMobile();
        }
      },
    );
  }
}