import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceContentProvider extends ChangeNotifier {
  String? selectedTeacherId;
  String? selectedStudentId;
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  AttendanceContentProvider() {
    fetchTeachersAndStudents();
  }

  Future<void> fetchTeachersAndStudents() async {
    try {
      final teacherSnapshot = await FirebaseFirestore.instance.collection('teachers').get();
      final studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      
      teachers = teacherSnapshot.docs
          .map((doc) => {
                'id': doc.id, 
                'name': doc.data()['fullName'] ?? 'Teacher ${doc.id}'
              })
          .toList();
          
      students = studentSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['fullName'] ?? 'Student ${doc.id}',
                'assignedTeacherId': doc.data()['assignedTeacherId'] ?? '',
              })
          .toList();
          
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching teachers and students: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String val) {
    searchQuery = val;
    notifyListeners();
  }

  void setSelectedTeacherId(String? id) {
    selectedTeacherId = id;
    notifyListeners();
  }

  void setSelectedStudentId(String? id) {
    selectedStudentId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
