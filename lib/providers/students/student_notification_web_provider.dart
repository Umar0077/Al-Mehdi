import 'package:flutter/material.dart';

class StudentNotificationWebProvider extends ChangeNotifier {
  String filterValue = 'All';
  final TextEditingController searchController = TextEditingController();

  void setFilterValue(String value) {
    filterValue = value;
    notifyListeners();
  }

  void notifySearchChanged() {
    notifyListeners();
  }
}
