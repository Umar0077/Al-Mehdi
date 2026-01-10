import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/class_completion_service.dart';

class TeacherClassesWebProvider extends ChangeNotifier {
  int tabIndex = 0;
  List<DocumentSnapshot> upcomingClasses = [];
  List<DocumentSnapshot> completedClasses = [];
  List<DocumentSnapshot> missedClasses = [];

  StreamSubscription<QuerySnapshot>? _classesSubscription;
  Timer? _refreshTimer;

  // New field to control schedule class screen visibility
  bool showScheduleClass = false;

  TeacherClassesWebProvider() {
    _startListeningToClasses();
    _startPeriodicRefresh();
    // Initialize class completion service
    ClassCompletionService().startCompletionMonitoring();
  }

  @override
  void dispose() {
    _classesSubscription?.cancel();
    _refreshTimer?.cancel();
    ClassCompletionService().stopCompletionMonitoring();
    super.dispose();
  }

  void _startListeningToClasses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _classesSubscription = FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: userId)
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
    showScheduleClass = false; // Hide schedule screen when tab is changed
    notifyListeners();
  }

  // New method to show/hide the schedule class screen
  void setShowScheduleClass(bool value) {
    showScheduleClass = value;
    notifyListeners();
  }

  Future<void> loadClasses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('classes')
              .where('teacherId', isEqualTo: userId)
              .get();

      _processClasses(query.docs);
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  void _processClasses(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    upcomingClasses.clear();
    completedClasses.clear();
    missedClasses.clear();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? 'upcoming').toString().toLowerCase();
      if (status == 'upcoming') {
        upcomingClasses.add(doc);
      } else if (status == 'completed') {
        completedClasses.add(doc);
      } else if (status == 'missed') {
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
