import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/notification_service.dart';
import '../admin_home_screen.dart';

class AssignStudentsProvider extends ChangeNotifier {
  final String teacherUid;
  List<Map<String, dynamic>> unassignedStudents = [];
  Map<String, bool> assignedStatus = {};
  bool loading = true;

  AssignStudentsProvider(this.teacherUid) {
    fetchUnassignedStudents();
  }

  Future<void> fetchUnassignedStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('unassigned_students')
        .where('assigned', isEqualTo: false)
        .get();
    unassignedStudents = snapshot.docs
        .map((doc) => {'uid': doc['uid'], 'name': doc['fullName']})
        .toList();
    assignedStatus = {for (var s in unassignedStudents) s['name']: false};
    loading = false;
    notifyListeners();
  }

  Future<void> assignStudent(BuildContext context, Map<String, dynamic> student) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(student['uid']);
      final teacherRef = FirebaseFirestore.instance.collection('teachers').doc(teacherUid);
      final unassignedStudentRef = FirebaseFirestore.instance.collection('unassigned_students').doc(student['uid']);
      final unassignedTeacherRef = FirebaseFirestore.instance.collection('unassigned_teachers').doc(teacherUid);
      transaction.update(studentRef, {'assignedTeacherId': teacherUid});
      transaction.update(teacherRef, {
        'assignedStudentId': FieldValue.arrayUnion([student['uid']]),
      });
      transaction.delete(unassignedStudentRef);
      transaction.delete(unassignedTeacherRef);
    });
    
    // Get teacher name for notifications
    final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(teacherUid).get();
    final teacherName = teacherDoc.data()?['fullName'] ?? 'Teacher';
    
    // Get student name for notifications  
    final studentDoc = await FirebaseFirestore.instance.collection('students').doc(student['uid']).get();
    final studentName = studentDoc.data()?['fullName'] ?? 'Student';
    
    print('🔔 AssignStudentsProvider - Sending assignment notifications');
    
    // Send notifications to both teacher and student using centralized function
    await NotificationService.sendTeacherStudentAssignmentNotifications(
      teacherId: teacherUid,
      studentId: student['uid'],
      teacherName: teacherName,
      studentName: studentName,
    );
    
    assignedStatus[student['name']] = true;
    notifyListeners();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminHomeScreen()),
      (route) => false,
    );
  }
}
