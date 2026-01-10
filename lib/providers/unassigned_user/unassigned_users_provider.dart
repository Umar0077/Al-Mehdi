import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UnassignedUsersProvider extends ChangeNotifier {
  List<Map<String, dynamic>> unassignedTeachers = [];
  List<Map<String, dynamic>> unassignedStudents = [];
  bool loading = true;

  UnassignedUsersProvider() {
    fetchUnassignedUsers();
  }

  Future<void> fetchUnassignedUsers() async {
    final teacherSnap = await FirebaseFirestore.instance.collection('teachers').get();
    final teachers = teacherSnap.docs
        .where((doc) {
          final ids = doc.data()['assignedStudentId'];
          return ids == null || (ids is List && ids.isEmpty);
        })
        .map((doc) => {
              'uid': doc['uid'] ?? doc.id,
              'name': doc['fullName'] ?? '',
              'role': 'Teacher',
              'avatar': 'https://i.pravatar.cc/100?u=${doc['uid'] ?? doc.id}',
              'assigned': false,
            })
        .toList();
    final studentSnap = await FirebaseFirestore.instance.collection('students').get();
    final students = studentSnap.docs
        .where((doc) {
          final tid = doc.data()['assignedTeacherId'];
          return tid == null || (tid is String && tid.isEmpty);
        })
        .map((doc) => {
              'uid': doc['uid'] ?? doc.id,
              'name': doc['fullName'] ?? '',
              'role': 'Student',
              'avatar': 'https://i.pravatar.cc/100?u=${doc['uid'] ?? doc.id}',
              'assigned': false,
            })
        .toList();
    unassignedTeachers = teachers;
    unassignedStudents = students;
    loading = false;
    notifyListeners();
  }
}
