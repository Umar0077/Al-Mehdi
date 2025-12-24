// import 'package:al_mehdi_online_school/teachers/teacher_home_screen/teacher_home_screen_mobile.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
// // Conditional import: use stub for mobile, real web screen for web
// import 'teacher_home_screen_stub.dart'
//     if (dart.library.html) 'teacher_home_screen_web.dart';
//
// class TeacherHomeScreen extends StatelessWidget {
//   const TeacherHomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     if (kIsWeb) {
//       return TeacherHomeScreenWeb();
//     } else {
//       return TeacherHomeScreenMobile();
//     }
//   }
// }

import 'package:al_mehdi_online_school/teachers/teacher_home_screen/teacher_home_screen_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: use stub for mobile, real web screen for web
import 'teacher_home_screen_stub.dart'
    if (dart.library.html) 'teacher_home_screen_web.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb && constraints.maxWidth >= 900) {
          // You can use constraints here to adapt the layout for web
          return TeacherHomeScreenWeb();
        } else {
          // Similarly, adjust layout for mobile if necessary
          return TeacherHomeScreenMobile();
        }
      },
    );
  }
}
