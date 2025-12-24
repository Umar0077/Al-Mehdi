import 'package:al_mehdi_online_school/teachers/teacher_chat/teacher_chat_mobile.dart';
import 'package:al_mehdi_online_school/teachers/teacher_chat/teacher_chat_web.dart';
import 'package:flutter/material.dart';

class TeacherChatScreen extends StatelessWidget {
  const TeacherChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (width >= 900) {
          // return const TeacherChatScreenWeb();
          return const TeacherChatScreenWeb();
        } else {
          return const TeacherChatScreenMobile();
        }
      },
    );
  }
}
