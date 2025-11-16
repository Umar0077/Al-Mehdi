import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../services/class_completion_service.dart';

class TeacherHomeMobileProvider extends ChangeNotifier {
  String? fullName;
  int selectedIndex = 0;

  // Jitsi and class logic
  bool jitsiInitialized = false;
  Map<String, dynamic>? joinableClass;
  bool hasJoined = false;

  TeacherHomeMobileProvider() {
    // Initialize all services in parallel for better performance
    _initializeServices();
  }

  /// Initialize all services simultaneously
  Future<void> _initializeServices() async {
    // Start all initialization tasks in parallel
    final futures = [
      fetchTeacherName(),
      _initJitsi(),
      checkForJoinableClass(),
    ];
    
    // Wait for all to complete
    await Future.wait(futures);
    
    // Start background services (non-blocking)
    _startBackgroundServices();
  }

  /// Start background services without blocking UI
  void _startBackgroundServices() {
    // Start class completion monitoring
    ClassCompletionService().startCompletionMonitoring();
    
    print('✅ Teacher mobile - All background services started');
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> fetchTeacherName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
      if (doc.exists) {
        fullName = doc['fullName'] ?? 'Teacher';
        notifyListeners();
      }
    }
  }

  Future<void> _initJitsi() async {
    try {
      await JitsiMeet().getPlatformVersion();
      jitsiInitialized = true;
    } catch (_) {
      jitsiInitialized = false;
    }
    notifyListeners();
  }

  Future<void> checkForJoinableClass() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();

    final query = await FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: user.uid)
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final teacherJoined = data['teacherJoined'] ?? false;
      final jitsiRoom = data['jitsiRoom'] ?? '';

      // Prefer scheduledAt (UTC) if present, else fallback to old logic
      DateTime? classDateTime;
      if (data['scheduledAt'] != null) {
        classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
      } else {
        final date = data['date'] ?? '';
        final time = data['time'] ?? '';
        classDateTime = _parseClassDateTime(date, time);
      }

      final canJoin = !teacherJoined &&
          classDateTime != null &&
          now.isAfter(classDateTime.subtract(const Duration(minutes: 5))) &&
          now.isBefore(classDateTime.add(const Duration(minutes: 10)));

      if (canJoin && jitsiRoom.isNotEmpty) {
        joinableClass = {...data, 'id': doc.id};
        hasJoined = false;
        notifyListeners();
        return;
      }
    }
    joinableClass = null;
    hasJoined = false;
    notifyListeners();
  }

  DateTime? _parseClassDateTime(String date, String time) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final timeReg = RegExp(r'(\d{1,2}):(\d{2})\s*([AP]M)', caseSensitive: false);
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

  Future<void> joinJitsiMeeting(BuildContext context) async {
    if (joinableClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No class to join.'),
        ),
      );
      return;
    }
    try {
      final jitsiRoom = joinableClass!['jitsiRoom'] ?? '';
      if (jitsiRoom.isEmpty) throw 'No Jitsi room found.';

      final options = JitsiMeetConferenceOptions(
        room: jitsiRoom,
        userInfo: JitsiMeetUserInfo(displayName: fullName ?? 'Teacher'),
        featureFlags: {
          "welcomepage.enabled": false,
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
        },
      );
      await JitsiMeet().join(options);

      // Only mark as joined after successful join
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(joinableClass!['id'])
          .update({'teacherJoined': true});
      hasJoined = true;
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join class: $e')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
