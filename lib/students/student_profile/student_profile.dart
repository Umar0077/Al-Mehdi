import 'package:al_mehdi_online_school/students/student_profile/student_profile_mobile.dart';
import 'package:al_mehdi_online_school/students/student_profile/student_profile_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          if (width >= 900) {
            return const StudentProfileWeb();
          } else {
            return const StudentProfileMobile();
          }
        } else {
          return const StudentProfileMobile();
        }
      },
    );
  }
}
