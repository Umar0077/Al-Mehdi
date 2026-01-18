import 'package:al_mehdi_online_school/views/students/student_attendance/student_attendance_mobile.dart';
import 'package:al_mehdi_online_school/views/students/student_attendance/student_attendance_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (width >= 900) {
          return const StudentAttendanceWebView();
        } else {
          return const StudentAttendanceMobileView();
        }
      },
    );
  }
}
