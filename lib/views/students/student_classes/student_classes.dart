import 'package:al_mehdi_online_school/views/students/student_classes/student_classes_mobile.dart';
import 'package:al_mehdi_online_school/views/students/student_classes/student_classes_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentClassesScreen extends StatelessWidget {
  const StudentClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          if (width >= 900) {
            return const StudentClassesWebView();
          } else {
            return const StudentClassesMobileView();
          }
        } else {
          return const StudentClassesMobileView();
        }
      },
    );
  }
}
