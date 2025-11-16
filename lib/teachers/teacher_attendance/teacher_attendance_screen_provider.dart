import 'package:flutter/material.dart';

class TeacherAttendanceScreenProvider extends ChangeNotifier {
  String? selectedValue;

  void setSelectedValue(String? value) {
    selectedValue = value;
    notifyListeners();
  }
}
