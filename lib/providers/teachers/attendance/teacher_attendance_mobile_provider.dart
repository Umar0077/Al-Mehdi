import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherAttendanceMobileProvider extends ChangeNotifier {
  String? selectedStudent;
  List<String> students = [];
  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool _isLoading = false;
  String _error = '';
  
  // Statistics
  int totalClasses = 0;
  int presentCount = 0;
  int absentCount = 0;
  int pendingCount = 0;

  TeacherAttendanceMobileProvider() {
    fetchStudents();
    searchController.addListener(() {
      notifyListeners();
    });
  }

  bool get isLoading => _isLoading;
  String get error => _error;
  double get attendanceRate => totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;

  Future<void> fetchStudents() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      
      final names = snapshot.docs
          .map((doc) => doc['studentName'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      
      students = names;
      await updateStatistics();
    } catch (e) {
      _error = 'Failed to fetch students: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatistics() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('status', isEqualTo: 'completed');

      // Apply student filter
      if (selectedStudent != null && selectedStudent!.isNotEmpty) {
        query = query.where('studentName', isEqualTo: selectedStudent);
      }

      final snapshot = await query.get();
      List<QueryDocumentSnapshot> filteredDocs = snapshot.docs;

      // Apply date filter
      if (startDate != null || endDate != null) {
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = data['date'] as String?;
          if (dateStr == null) return false;
          
          try {
            final classDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            if (startDate != null && classDate.isBefore(startDate!)) return false;
            if (endDate != null && classDate.isAfter(endDate!)) return false;
            return true;
          } catch (e) {
            return false;
          }
        }).toList();
      }

      totalClasses = filteredDocs.length;
      presentCount = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['attendanceStatus'] == 'present';
      }).length;
      
      absentCount = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['attendanceStatus'] == 'absent';
      }).length;
      
      pendingCount = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return !data.containsKey('attendanceStatus');
      }).length;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update statistics: $e';
      notifyListeners();
    }
  }

  String get searchQuery => searchController.text.trim().toLowerCase();

  void setSelectedStudent(String? value, ValueChanged<String?> onChanged) {
    selectedStudent = value;
    onChanged(value);
    updateStatistics();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    updateStatistics();
    notifyListeners();
  }

  void clearFilters() {
    selectedStudent = null;
    startDate = null;
    endDate = null;
    searchController.clear();
    updateStatistics();
    notifyListeners();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> refreshData() async {
    await fetchStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
