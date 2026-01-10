import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/chat_service.dart';
import '../../../services/notification_service.dart';

class StudentChatMobileProvider extends ChangeNotifier {
  String? assignedTeacherId;
  String? teacherName;
  String? teacherAvatar;
  bool isLoading = true;
  String? error;
  List<String>? fcm_token;

  // Local message state management for optimistic updates
  final List<Map<String, dynamic>> _localMessages = [];
  final Map<String, String> _messageStatus =
      {}; // tempId -> status (sending/sent/failed)
  bool _isSending = false;

  StudentChatMobileProvider() {
    _loadAssignedTeacher();
  }

  // Getters for local message state
  List<Map<String, dynamic>> get localMessages => _localMessages;
  Map<String, String> get messageStatus => _messageStatus;
  bool get isSending => _isSending;

  // Add local message for optimistic UI updates
  void addLocalMessage(Map<String, dynamic> message) {
    _localMessages.add(message);
    notifyListeners();
  }

  // Update message status (sending -> sent -> failed)
  void updateMessageStatus(String tempId, String status) {
    _messageStatus[tempId] = status;
    notifyListeners();
  }

  // Remove local message (when confirmed sent)
  void removeLocalMessage(String tempId) {
    _localMessages.removeWhere((msg) => msg['tempId'] == tempId);
    _messageStatus.remove(tempId);
    notifyListeners();
  }

  // Fast message sending with optimistic updates
  Future<void> sendMessageFast(String message) async {
    if (assignedTeacherId == null) return;

    _isSending = true;
    notifyListeners();

    // Generate temporary ID for optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _isSending = false;
      notifyListeners();
      return;
    }

    // Add message locally for immediate UI update
    final localMessage = {
      'tempId': tempId,
      'message': message,
      'senderId': currentUser.uid,
      'timestamp': Timestamp.now(),
      'senderName': 'You',
      'senderRole': 'student',
    };

    addLocalMessage(localMessage);
    updateMessageStatus(tempId, 'sending');

    try {
      // Send message using optimistic method
      await ChatService.sendMessageOptimistic(
        receiverId: assignedTeacherId!,
        message: message,
        senderName: 'Student', // Will be updated with actual name
        senderRole: 'student',
      );

      // Update status to sent
      updateMessageStatus(tempId, 'sent');

      // Send FCM notification asynchronously
      _sendFCMNotificationAsync(message);

      // Remove from local messages after short delay (message will appear in stream)
      Future.delayed(const Duration(milliseconds: 500), () {
        removeLocalMessage(tempId);
      });
    } catch (e) {
      updateMessageStatus(tempId, 'failed');
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Get current student info for messaging
  Future<Map<String, String?>> getCurrentStudentInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {'name': null, 'id': null};

      final studentDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(currentUser.uid)
              .get();

      final studentData = studentDoc.data();
      return {
        'name': studentData?['fullName'] ?? 'Student',
        'id': currentUser.uid,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting student info: $e');
      }
      return {'name': 'Student', 'id': FirebaseAuth.instance.currentUser?.uid};
    }
  }

  // Enhanced fast message sending with proper student name
  Future<void> sendMessageWithStudentInfo(String message) async {
    if (assignedTeacherId == null) return;

    final studentInfo = await getCurrentStudentInfo();
    final studentName = studentInfo['name'] ?? 'Student';

    _isSending = true;
    notifyListeners();

    // Generate temporary ID for optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _isSending = false;
      notifyListeners();
      return;
    }

    // Add message locally for immediate UI update
    final localMessage = {
      'tempId': tempId,
      'message': message,
      'senderId': currentUser.uid,
      'timestamp': Timestamp.now(),
      'senderName': studentName,
      'senderRole': 'student',
    };

    addLocalMessage(localMessage);
    updateMessageStatus(tempId, 'sending');

    try {
      // Send message using optimistic method with proper student name
      await ChatService.sendMessageOptimistic(
        receiverId: assignedTeacherId!,
        message: message,
        senderName: studentName,
        senderRole: 'student',
      );

      // Update status to sent
      updateMessageStatus(tempId, 'sent');

      // Send FCM notification asynchronously
      _sendFCMNotificationAsync(message, studentName);

      // Remove from local messages after short delay (message will appear in stream)
      Future.delayed(const Duration(milliseconds: 500), () {
        removeLocalMessage(tempId);
      });
    } catch (e) {
      updateMessageStatus(tempId, 'failed');
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Updated FCM notification method with student name
  void _sendFCMNotificationAsync(String message, [String? studentName]) async {
    try {
      if (fcm_token != null && fcm_token!.isNotEmpty) {
        final List<Future> notificationFutures = [];
        final senderName = studentName ?? 'Student';

        // Send to all teacher FCM tokens in parallel
        for (String token in fcm_token!) {
          if (token.isNotEmpty) {
            notificationFutures.add(
              NotificationService.sendFCMNotification(
                title: 'New Message from $senderName',
                body:
                    message.length > 50
                        ? '${message.substring(0, 50)}...'
                        : message,
                token: token,
              ),
            );
          }
        }

        // Send all notifications in parallel without waiting
        if (notificationFutures.isNotEmpty) {
          Future.wait(notificationFutures).catchError((error) {
            if (kDebugMode) {
              print('⚠️ Some FCM notifications failed: $error');
            }
            return <dynamic>[]; // Return empty list for error handling
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM notification error: $e');
      }
    }
  }

  // Retry failed message
  Future<void> retryMessage(String tempId) async {
    final message = _localMessages.firstWhere(
      (msg) => msg['tempId'] == tempId,
      orElse: () => {},
    );

    if (message.isNotEmpty) {
      final messageText = message['message'] as String;
      removeLocalMessage(tempId);
      await sendMessageFast(messageText);
    }
  }

  // Clear all local messages
  void clearLocalMessages() {
    _localMessages.clear();
    _messageStatus.clear();
    notifyListeners();
  }

  Future<void> _loadAssignedTeacher() async {
    try {
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
      final studentData = studentDoc.data();
      if (studentData == null || studentData['assignedTeacherId'] == null) {
        assignedTeacherId = null;
        isLoading = false;
        notifyListeners();
        return;
      }
      assignedTeacherId = studentData['assignedTeacherId'];
      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(assignedTeacherId)
              .get();
      final teacherData = teacherDoc.data();
      teacherName = teacherData?['fullName'] ?? 'Teacher';
      fcm_token =
          teacherData?['fcmTokens'] != null
              ? List<String>.from(teacherData!['fcmTokens'])
              : [];
      teacherAvatar =
          teacherData?['profilePictureUrl'] ??
          'https://i.pravatar.cc/100?u=$assignedTeacherId';
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
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
}
