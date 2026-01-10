import 'package:al_mehdi_online_school/views/teachers/teacher_attendance/teacher_attendance_mobile.dart';
import 'package:al_mehdi_online_school/views/teachers/teacher_attendance/teacher_attendance_web.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/teachers/attendance/teacher_attendance_screen_provider.dart';

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider<TeacherAttendanceScreenProvider>(
      create: (_) => TeacherAttendanceScreenProvider(),
      child: Consumer<TeacherAttendanceScreenProvider>(
        builder: (context, provider, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (width >= 900) {
                return TeacherAttendanceWebView(
                  selectedValue: provider.selectedValue,
                  onChanged: provider.setSelectedValue,
                );
              } else {
                return TeacherAttendanceMobileView(
                  selectedValue: provider.selectedValue,
                  onChanged: provider.setSelectedValue,
                );
              }
            },
          );
        },
      ),
    );
  }
}
