import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentAttendanceWebProvider extends ChangeNotifier {
  int attended = 0;
  int total = 0;
  int missedForChart = 0;
  int missedForCard = 0;
  double percentage = 0;
  Map<String, double> dataMap = {};
  bool loading = true;
  String error = '';

  Future<void> fetchAttendance() async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      final docs = snapshot.docs;
      total = docs.length;
      attended = docs
          .where((doc) => (doc.data()['attendanceStatus'] == 'present'))
          .length;
      missedForChart = total - attended;
      missedForCard = docs
          .where((doc) => (doc.data()['attendanceStatus'] == 'absent'))
          .length;
      percentage = total == 0 ? 0 : (attended / total) * 100;
      final dataMapRaw = {
        "Attended": attended.toDouble(),
        "Missed": missedForChart.toDouble(),
      };
      dataMap = Map.fromEntries(dataMapRaw.entries.where((e) => e.value > 0));
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }
}
