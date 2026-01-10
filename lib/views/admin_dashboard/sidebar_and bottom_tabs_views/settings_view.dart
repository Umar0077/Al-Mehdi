import 'package:flutter/material.dart';

import 'admin_settings_mobile.dart';
import 'admin_settings_web.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (width >= 900) {
          // Desktop Layout
          return const AdminSettingsViewWeb();
        } else {
          // Mobile Layout
          return const AdminSettingsViewMobile();
        }
      },
    );
  }
}
