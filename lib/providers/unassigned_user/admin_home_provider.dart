import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomeProvider extends ChangeNotifier {
  int totalUsers = 0;
  int activeClasses = 0;
  int unassignedUsers = 0;
  bool loading = true;

  // Overlay screen type
  String? overlayScreen; // 'activeClasses', 'totalUsers', 'unassignedUsers', 'feesStatus'

  // Main content replacement logic
  String? mainContentScreen; // 'activeClasses', 'totalUsers', 'unassignedUsers', 'feesStatus', null for dashboard

  AdminHomeProvider() {
    fetchDashboardStats();
  }

  void showOverlay(String screen) {
    overlayScreen = screen;
    notifyListeners();
  }

  void closeOverlay() {
    overlayScreen = null;
    notifyListeners();
  }

  void showMainContent(String screen) {
    mainContentScreen = screen;
    notifyListeners();
  }

  void showDashboard() {
    mainContentScreen = null;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    loading = true;
    notifyListeners();
    final studentSnap = await FirebaseFirestore.instance.collection('students').get();
    final teacherSnap = await FirebaseFirestore.instance.collection('teachers').get();
    final classSnap = await FirebaseFirestore.instance.collection('classes').where('status', isEqualTo: 'active').get();
    final unassignedTeachers = teacherSnap.docs.where((doc) {
      final data = doc.data();
      final ids = data['assignedStudentId'];
      return ids == null || (ids is List && ids.isEmpty);
    }).length;
    final unassignedStudents = studentSnap.docs.where((doc) {
      final data = doc.data();
      final tid = data['assignedTeacherId'];
      return tid == null || (tid is String && tid.isEmpty);
    }).length;
    totalUsers = studentSnap.docs.length + teacherSnap.docs.length;
    activeClasses = classSnap.docs.length;
    unassignedUsers = unassignedTeachers + unassignedStudents;
    loading = false;
    notifyListeners();
  }
}
