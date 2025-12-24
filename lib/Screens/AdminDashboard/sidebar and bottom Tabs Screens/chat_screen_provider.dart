import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreenProvider extends ChangeNotifier {
  int? selectedChatIndex;
  List<Map<String, dynamic>> chatRooms = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String searchTerm = '';

  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> studentsForTeacher = [];
  String? selectedTeacherId;
  String? selectedStudentId;
  String? selectedTeacherName;
  String? selectedStudentName;
  bool teacherHasChats = true;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> teachersForStudent = [];
  bool studentHasChats = true;

  ChatScreenProvider() {
    _loadTeachers();
    _loadStudents();
    _loadChatRooms();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    searchTerm = searchController.text.trim();
    notifyListeners();
  }

  Future<void> _loadTeachers() async {
    final snapshot = await FirebaseFirestore.instance.collection('teachers').get();
    teachers = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['fullName'] ?? 'Teacher'}).toList();
    notifyListeners();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').get();
    students = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['fullName'] ?? 'Student'}).toList();
    notifyListeners();
  }

  Future<void> _loadTeachersForStudent(String studentId) async {
    final chatSnapshot = await FirebaseFirestore.instance.collection('chatRooms').where('participants', arrayContains: studentId).get();
    final teacherIds = <String>{};
    for (var doc in chatSnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      for (final id in participants) {
        if (id != studentId) teacherIds.add(id);
      }
    }
    if (teacherIds.isEmpty) {
      teachersForStudent = [];
      studentHasChats = false;
      selectedTeacherId = null;
      selectedTeacherName = null;
      notifyListeners();
      return;
    }
    final teachersSnapshot = await FirebaseFirestore.instance.collection('teachers').where(FieldPath.documentId, whereIn: teacherIds.toList()).get();
    teachersForStudent = teachersSnapshot.docs.map((doc) => {'id': doc.id, 'name': doc['fullName'] ?? 'Teacher'}).toList();
    studentHasChats = true;
    selectedTeacherId = null;
    selectedTeacherName = null;
    notifyListeners();
  }

  Future<void> _loadStudentsForTeacher(String teacherId) async {
    final chatSnapshot = await FirebaseFirestore.instance.collection('chatRooms').where('participants', arrayContains: teacherId).get();
    final studentIds = <String>{};
    for (var doc in chatSnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      for (final id in participants) {
        if (id != teacherId) studentIds.add(id);
      }
    }
    if (studentIds.isEmpty) {
      studentsForTeacher = [];
      teacherHasChats = false;
      selectedStudentId = null;
      selectedStudentName = null;
      notifyListeners();
      return;
    }
    final studentsSnapshot = await FirebaseFirestore.instance.collection('students').where(FieldPath.documentId, whereIn: studentIds.toList()).get();
    studentsForTeacher = studentsSnapshot.docs.map((doc) => {'id': doc.id, 'name': doc['fullName'] ?? 'Student'}).toList();
    teacherHasChats = true;
    selectedStudentId = null;
    selectedStudentName = null;
    notifyListeners();
  }

  Future<void> _loadChatRooms() async {
    isLoading = true;
    notifyListeners();
    final snapshot = await FirebaseFirestore.instance.collection('chatRooms').orderBy('updatedAt', descending: true).get();
    List<Map<String, dynamic>> rooms = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants']);
      final studentFutures = participants.map((id) => FirebaseFirestore.instance.collection('students').doc(id).get()).toList();
      final teacherFutures = participants.map((id) => FirebaseFirestore.instance.collection('teachers').doc(id).get()).toList();
      final studentDocs = await Future.wait(studentFutures);
      final teacherDocs = await Future.wait(teacherFutures);
      String? studentId;
      String? teacherId;
      String studentName = '';
      String teacherName = '';
      for (int i = 0; i < participants.length; i++) {
        final id = participants[i];
        final studentDoc = studentDocs[i];
        if (studentDoc.exists) {
          studentId = id;
          studentName = studentDoc.data()?['fullName'] ?? 'Student';
        }
        final teacherDoc = teacherDocs[i];
        if (teacherDoc.exists) {
          teacherId = id;
          teacherName = teacherDoc.data()?['fullName'] ?? 'Teacher';
        }
      }
      rooms.add({
        'id': doc.id,
        'studentId': studentId,
        'teacherId': teacherId,
        'studentName': studentName,
        'teacherName': teacherName,
        'lastMessage': data['lastMessage'] ?? '',
        'lastMessageTime': data['lastMessageTime'],
        'avatar': 'https://i.pravatar.cc/100?u=${studentId ?? teacherId}',
      });
    }
    chatRooms = rooms;
    isLoading = false;
    notifyListeners();
  }

  void setSelectedChatIndex(int? index) {
    selectedChatIndex = index;
    notifyListeners();
  }

  void setSelectedTeacherId(String? val) async {
    selectedTeacherId = val;
    selectedTeacherName = val == null
        ? null
        : (selectedStudentId == null
            ? teachers.firstWhere((t) => t['id'] == val)['name']
            : teachersForStudent.firstWhere((t) => t['id'] == val)['name']);
    selectedStudentId = null;
    selectedStudentName = null;
    studentsForTeacher = [];
    teacherHasChats = true;
    notifyListeners();
    if (val != null) {
      await _loadStudentsForTeacher(val);
    }
  }

  void setSelectedStudentId(String? val) async {
    selectedStudentId = val;
    selectedStudentName = val == null
        ? null
        : (selectedTeacherId == null
            ? students.firstWhere((s) => s['id'] == val)['name']
            : studentsForTeacher.firstWhere((s) => s['id'] == val)['name']);
    selectedTeacherId = null;
    selectedTeacherName = null;
    teachersForStudent = [];
    studentHasChats = true;
    notifyListeners();
    if (val != null) {
      await _loadTeachersForStudent(val);
    }
  }

  // Public methods for UI compatibility
  Future<void> loadStudentsForTeacher(String teacherId) async {
    await _loadStudentsForTeacher(teacherId);
  }
  Future<void> loadTeachersForStudent(String studentId) async {
    await _loadTeachersForStudent(studentId);
  }
  void setSearchTerm(String val) {
    searchTerm = val;
    notifyListeners();
  }
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime messageTime;
    if (timestamp is Timestamp) {
      messageTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      messageTime = timestamp;
    } else {
      return '';
    }
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
