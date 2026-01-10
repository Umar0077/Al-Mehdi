import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../main/student_main_view.dart';
// Conditional import
import 'student_home_screen_stub.dart'
    if (dart.library.html) 'student_home_screen_web.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb && constraints.maxWidth >= 900) {
          return const StudentHomeScreenWeb();
        } else {
          return const StudentMainView();
        }
      },
    );
  }
}
