import 'package:al_mehdi_online_school/views/students/student_chat/student_chat_mobile.dart';
import 'package:al_mehdi_online_school/views/students/student_chat/student_chat_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentChatScreen extends StatelessWidget {
  final String? initialTeacherId;
  const StudentChatScreen({super.key, this.initialTeacherId});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          if (width <= 900) {
            return const StudentChatMobileView();
          } else {
            return const StudentChatWebView();
          }
        } else {
          return const StudentChatMobileView();
        }
      },
    );
  }
}
