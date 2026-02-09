import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'teacher_home_screen_mobile.dart';
// Conditional import: use stub for mobile, real web screen for web
import 'teacher_home_screen_stub.dart'
    if (dart.library.js_interop) 'teacher_home_screen_web.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb && constraints.maxWidth >= 900) {
          return TeacherHomeScreenWeb();
        } else {
          return const TeacherHomeScreenMobile();
        }
      },
    );
  }
}
