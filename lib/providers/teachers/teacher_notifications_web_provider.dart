import 'package:flutter/material.dart';

class TeacherNotificationWebProvider extends ChangeNotifier {
  String filterValue = 'All';
  final TextEditingController searchController = TextEditingController();

  void setFilterValue(String value) {
    filterValue = value;
    notifyListeners();
  }

  void onSearchChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
