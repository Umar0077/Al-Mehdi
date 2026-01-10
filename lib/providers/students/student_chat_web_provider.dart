import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/chat_service.dart';
import '../../services/notification_service.dart';

class StudentChatWebProvider extends ChangeNotifier {
  int? selectedChatIndex;
  String? assignedTeacherId;
  String? teacherName;
  String? teacherAvatar;
  bool isLoading = true;
  String searchQuery = '';
  List<String>? fcm_token;

  // Cache student info to avoid repeated Firestore queries
  String? _cachedStudentName;
  String? _cachedStudentId;

  // Local message state management for optimistic updates
  final List<Map<String, dynamic>> _localMessages = [];
  final Map<String, String> _messageStatus =
      {}; // tempId -> status (sending/sent/failed)
  bool _isSending = false;

  StudentChatWebProvider({String? initialTeacherId}) {
    if (initialTeacherId != null) {
      assignedTeacherId = initialTeacherId;
      selectedChatIndex = 0;
    }
    _initializeStudentInfo();
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

  // Fast message sending with optimistic updates for web
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

    // Get student info from cache (no await needed!)
    final studentInfo = getCurrentStudentInfo();
    final studentName = studentInfo['name'] ?? 'Student';

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
      // Send message using optimistic method
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

  // Initialize student info once to avoid repeated queries
  Future<void> _initializeStudentInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _cachedStudentId = currentUser.uid;

      final studentDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(currentUser.uid)
              .get();

      final studentData = studentDoc.data();
      _cachedStudentName = studentData?['fullName'] ?? 'Student';

      if (kDebugMode) {
        print('✅ Student info cached: $_cachedStudentName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching student info: $e');
      }
      _cachedStudentName = 'Student';
    }
  }

  // Get current student info for messaging (now uses cache)
  Map<String, String?> getCurrentStudentInfo() {
    return {
      'name': _cachedStudentName ?? 'Student',
      'id': _cachedStudentId ?? FirebaseAuth.instance.currentUser?.uid,
    };
  }

  // Send FCM notification asynchronously without blocking UI
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
    final teacherId = studentData['assignedTeacherId'];
    final teacherDoc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .get();
    final teacherData = teacherDoc.data();
    assignedTeacherId = teacherId;
    teacherName = teacherData?['fullName'] ?? 'Teacher';
    teacherAvatar =
        teacherData?['profilePictureUrl'] ??
        'https://i.pravatar.cc/100?u=$teacherId';
    fcm_token =
        teacherData?['fcmTokens'] != null
            ? List<String>.from(teacherData!['fcmTokens'])
            : [];
    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String val) {
    searchQuery = val.trim();
    notifyListeners();
  }

  void selectChatIndex(int idx) {
    selectedChatIndex = idx;
    notifyListeners();
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
