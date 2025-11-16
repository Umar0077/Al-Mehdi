import 'package:al_mehdi_online_school/teachers/teacher_classes_screen/teacher_classes_mobile.dart';
import 'package:al_mehdi_online_school/teachers/teacher_classes_screen/teacher_classes_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => TeacherClassesScreenState();
}

class TeacherClassesScreenState extends State<TeacherClassesScreen> {
  bool showScheduleClass = false;
  int resetKey = 0;

  void setShowScheduleClass(bool value) {
    setState(() {
      showScheduleClass = value;
    });
  }

  void resetToOriginalScreen() {
    setState(() {
      showScheduleClass = false;
      resetKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          if (width >= 900) {
            return TeacherClassesWebView(
              key: ValueKey(resetKey),
              showScheduleClass: showScheduleClass,
              setShowScheduleClass: setShowScheduleClass,
            );
          } else {
            return const TeacherClassesMobileView();
          }
        } else {
          return const TeacherClassesMobileView();
        }
      },
    );
  }
}
