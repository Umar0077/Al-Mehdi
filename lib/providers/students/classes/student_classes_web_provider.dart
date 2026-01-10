import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/class_completion_service.dart';

class StudentClassesWebProvider extends ChangeNotifier {
  int tabIndex = 0;
  List<DocumentSnapshot> upcomingClasses = [];
  List<DocumentSnapshot> completedClasses = [];
  List<DocumentSnapshot> missedClasses = [];

  StreamSubscription<QuerySnapshot>? _classesSubscription;
  Timer? _refreshTimer;

  StudentClassesWebProvider() {
    _startListeningToClasses();
    _startPeriodicRefresh();
    // Initialize class completion service
    ClassCompletionService().startCompletionMonitoring();
  }

  @override
  void dispose() {
    _classesSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startListeningToClasses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _classesSubscription = FirebaseFirestore.instance
        .collection('classes')
        .where('studentId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          _processClasses(snapshot.docs);
        });
  }

  void _startPeriodicRefresh() {
    // Refresh every minute to handle time-based transitions
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        loadClasses();
      }
    });
  }

  void setTabIndex(int index) {
    tabIndex = index;
    notifyListeners();
  }

  Future<void> loadClasses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final query =
        await FirebaseFirestore.instance
            .collection('classes')
            .where('studentId', isEqualTo: userId)
            .get();

    _processClasses(query.docs);
  }

  void _processClasses(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    upcomingClasses.clear();
    completedClasses.clear();
    missedClasses.clear();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime? classDateTime;
      if (data['scheduledAt'] != null) {
        classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
      } else {
        // fallback for old data
        final date = data['date'] ?? '';
        final time = data['time'] ?? '';
        classDateTime = _parseClassDateTime(date, time);
      }
      final studentJoined = data['studentJoined'] ?? false;

      // Check if class is within the joinable window (5 minutes before to 10 minutes after)
      final canJoin =
          classDateTime != null &&
          now.isAfter(classDateTime.subtract(const Duration(minutes: 5))) &&
          now.isBefore(classDateTime.add(const Duration(minutes: 10)));

      // Class is completed only after 10 minutes AND student joined
      final isCompleted =
          studentJoined &&
          classDateTime != null &&
          now.isAfter(classDateTime.add(const Duration(minutes: 10)));

      // Class is missed if student never joined and it's past the 10-minute window
      final isMissed =
          !studentJoined &&
          classDateTime != null &&
          now.isAfter(classDateTime.add(const Duration(minutes: 10)));

      if (canJoin) {
        // Show in upcoming if within joinable window
        upcomingClasses.add(doc);
      } else if (isCompleted) {
        completedClasses.add(doc);
      } else if (isMissed) {
        missedClasses.add(doc);
      }
    }
    notifyListeners();
  }

  DateTime? _parseClassDateTime(String date, String time) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        // Parse time with AM/PM
        final timeReg = RegExp(
          r'(\d{1,2}):(\d{2})\s*([AP]M)',
          caseSensitive: false,
        );
        final match = timeReg.firstMatch(time);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          final period = match.group(3)!.toUpperCase();

          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;

          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}
    return null;
  }
}
