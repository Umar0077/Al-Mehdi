import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class AssignTeachersProvider extends ChangeNotifier {
  final String studentUid;
  List<Map<String, dynamic>> unassignedTeachers = [];
  Map<String, bool> assignedStatus = {};
  bool loading = true;

  List<Map<String, dynamic>> assignedTeachers = [];
  bool loadingAssigned = false;

  AssignTeachersProvider(this.studentUid) {
    fetchUnassignedTeachers();
  }

  Future<void> fetchUnassignedTeachers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('unassigned_teachers')
        .where('assigned', isEqualTo: false)
        .get();
    unassignedTeachers = snapshot.docs
        .map((doc) => {'uid': doc['uid'], 'name': doc['fullName']})
        .toList();
    assignedStatus = {for (var t in unassignedTeachers) t['name']: false};
    loading = false;
    notifyListeners();
    if (unassignedTeachers.isEmpty) {
      fetchAssignedTeachers();
    }
  }

  Future<void> fetchAssignedTeachers() async {
    loadingAssigned = true;
    notifyListeners();
    final snapshot = await FirebaseFirestore.instance.collection('teachers').get();
    final assigned = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final assignedStudentId = data['assignedStudentId'] ?? [];
      int studentCount = assignedStudentId is List ? assignedStudentId.length : 0;
      assigned.add({
        'uid': doc['uid'] ?? doc.id,
        'name': data['fullName'] ?? '',
        'studentCount': studentCount,
        'role': 'Teacher',
        'avatar': 'https://i.pravatar.cc/100?u=${doc['uid'] ?? doc.id}',
        'raw': data,
      });
    }
    assignedTeachers = assigned;
    loadingAssigned = false;
    notifyListeners();
  }

  Future<void> assignTeacher(BuildContext context, Map<String, dynamic> teacher) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final teacherRef = FirebaseFirestore.instance.collection('teachers').doc(teacher['uid']);
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentUid);
      final unassignedTeacherRef = FirebaseFirestore.instance.collection('unassigned_teachers').doc(teacher['uid']);
      final unassignedStudentRef = FirebaseFirestore.instance.collection('unassigned_students').doc(studentUid);
      transaction.update(teacherRef, {
        'assignedStudentId': FieldValue.arrayUnion([studentUid]),
      });
      transaction.update(studentRef, {'assignedTeacherId': teacher['uid']});
      transaction.delete(unassignedTeacherRef);
      transaction.delete(unassignedStudentRef);
    });
    
    // Get teacher name for notifications
    final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(teacher['uid']).get();
    final teacherName = teacherDoc.data()?['fullName'] ?? 'Teacher';
    
    // Get student name for notifications
    final studentDoc = await FirebaseFirestore.instance.collection('students').doc(studentUid).get();
    final studentName = studentDoc.data()?['fullName'] ?? 'Student';
    
    print('🔔 AssignTeachersProvider - Sending assignment notifications');
    
    // Send notifications to both teacher and student using centralized function
    await NotificationService.sendTeacherStudentAssignmentNotifications(
      teacherId: teacher['uid'],
      studentId: studentUid,
      teacherName: teacherName,
      studentName: studentName,
    );
    
    assignedStatus[teacher['name']] = true;
    notifyListeners();
  }
}
