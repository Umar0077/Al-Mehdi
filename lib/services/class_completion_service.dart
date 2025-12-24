import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Service to handle automatic class completion logic
class ClassCompletionService {
  static final ClassCompletionService _instance = ClassCompletionService._internal();
  factory ClassCompletionService() => _instance;
  ClassCompletionService._internal();

  Timer? _completionTimer;

  /// Starts monitoring for classes that need to be marked as completed
  void startCompletionMonitoring() {
    // Check every minute for classes that should be completed
    _completionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndCompleteClasses();
    });
  }

  /// Stops the completion monitoring
  void stopCompletionMonitoring() {
    _completionTimer?.cancel();
    _completionTimer = null;
  }

  /// Checks for classes that should be marked as completed
  Future<void> _checkAndCompleteClasses() async {
    try {
      final now = DateTime.now();
      
      // Query for classes that have studentJoined = true
      // We'll filter out completed ones in memory to avoid composite index
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .where('studentJoined', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int updatesCount = 0;

      for (var doc in query.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final studentJoinTime = data['studentJoinTime'] as Timestamp?;
        
        // Skip if already completed (in-memory filtering)
        if (status == 'completed') continue;
        
        if (studentJoinTime != null) {
          final joinTime = studentJoinTime.toDate();
          final timeDifference = now.difference(joinTime);
          
          // If student has been in class for more than 10 minutes, mark as completed
          if (timeDifference.inMinutes >= 10) {
            batch.update(doc.reference, {
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
              'attendanceStatus': 'present', // Mark student as present
            });
            updatesCount++;
          }
        }
      }

      // Commit batch update if there are any updates
      if (updatesCount > 0) {
        await batch.commit();
        print('✅ Marked $updatesCount classes as completed');
      }
    } catch (e) {
      print('❌ Error in class completion check: $e');
    }
  }

  /// Manually check if a specific class should be completed
  Future<void> checkSpecificClass(String classId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final studentJoined = data['studentJoined'] as bool? ?? false;
      final studentJoinTime = data['studentJoinTime'] as Timestamp?;
      final status = data['status'] as String? ?? '';

      if (studentJoined && studentJoinTime != null && status != 'completed') {
        final now = DateTime.now();
        final joinTime = studentJoinTime.toDate();
        final timeDifference = now.difference(joinTime);

        if (timeDifference.inMinutes >= 10) {
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(classId)
              .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'attendanceStatus': 'present',
          });
          print('✅ Class $classId marked as completed');
        }
      }
    } catch (e) {
      print('❌ Error checking specific class: $e');
    }
  }
}
