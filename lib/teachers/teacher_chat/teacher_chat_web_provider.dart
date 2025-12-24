import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class TeacherChatWebProvider extends ChangeNotifier {
  int? selectedChatIndex;
  String? selectedStudentId;
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  
  // Cache teacher info to avoid repeated Firestore queries
  String? _cachedTeacherName;
  String? _cachedTeacherId;
  
  // Local message state management for optimistic updates
  final List<Map<String, dynamic>> _localMessages = [];
  final Map<String, String> _messageStatus = {}; // tempId -> status (sending/sent/failed)
  bool _isSending = false;

  TeacherChatWebProvider() {
    _initializeTeacherInfo();
    loadAssignedStudents();
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
  Future<void> sendMessageFast(String message, String receiverId) async {
    if (receiverId.isEmpty) return;

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

    // Get teacher info from cache (no await needed!)
    final teacherInfo = getCurrentTeacherInfo();
    final teacherName = teacherInfo['name'] ?? 'Teacher';

    // Add message locally for immediate UI update
    final localMessage = {
      'tempId': tempId,
      'message': message,
      'senderId': currentUser.uid,
      'timestamp': Timestamp.now(),
      'senderName': teacherName,
      'senderRole': 'teacher',
    };

    addLocalMessage(localMessage);
    updateMessageStatus(tempId, 'sending');

    try {
      // Send message using optimistic method
      await ChatService.sendMessageOptimistic(
        receiverId: receiverId,
        message: message,
        senderName: teacherName,
        senderRole: 'teacher',
      );

      // Update status to sent
      updateMessageStatus(tempId, 'sent');

      // Send FCM notification asynchronously
      _sendFCMNotificationAsync(message, receiverId, teacherName);

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

  // Initialize teacher info once to avoid repeated queries
  Future<void> _initializeTeacherInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _cachedTeacherId = currentUser.uid;
      
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(currentUser.uid)
          .get();

      final teacherData = teacherDoc.data();
      _cachedTeacherName = teacherData?['fullName'] ?? 'Teacher';
      
      if (kDebugMode) {
        print('✅ Teacher info cached: $_cachedTeacherName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching teacher info: $e');
      }
      _cachedTeacherName = 'Teacher';
    }
  }

  // Get current teacher info for messaging (now uses cache)
  Map<String, String?> getCurrentTeacherInfo() {
    return {
      'name': _cachedTeacherName ?? 'Teacher',
      'id': _cachedTeacherId ?? FirebaseAuth.instance.currentUser?.uid,
    };
  }

  // Send FCM notification asynchronously without blocking UI
  void _sendFCMNotificationAsync(String message, String receiverId, [String? teacherName]) async {
    try {
      // Get student's FCM tokens
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(receiverId)
          .get();
      
      if (studentDoc.exists) {
        final studentData = studentDoc.data();
        final dynamic tokens = studentData?['fcmTokens'];
        
        if (tokens != null) {
          final List<Future> notificationFutures = [];
          final senderName = teacherName ?? 'Teacher';

          if (tokens is List) {
            // Send to multiple tokens in parallel
            for (var token in tokens) {
              if (token != null && token.toString().isNotEmpty) {
                notificationFutures.add(
                  NotificationService.sendFCMNotification(
                    title: 'New Message from $senderName',
                    body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
                    token: token.toString(),
                  )
                );
              }
            }
          } else if (tokens is String && tokens.isNotEmpty) {
            notificationFutures.add(
              NotificationService.sendFCMNotification(
                title: 'New Message from $senderName',
                body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
                token: tokens,
              )
            );
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

    if (message.isNotEmpty && selectedStudentId != null) {
      final messageText = message['message'] as String;
      removeLocalMessage(tempId);
      await sendMessageFast(messageText, selectedStudentId!);
    }
  }

  // Clear all local messages
  void clearLocalMessages() {
    _localMessages.clear();
    _messageStatus.clear();
    notifyListeners();
  }

  // Enhanced student loading with FCM token information
  Future<void> loadAssignedStudentsWithFCM({String? initialStudentId}) async {
    isLoading = true;
    notifyListeners();
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('assignedTeacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      
      students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullName'] ?? 'Student',
          'avatar': data['profilePictureUrl'] ?? 'https://i.pravatar.cc/100?u=${doc.id}',
          'fcmTokens': data['fcmTokens'], // Include FCM tokens for notifications
          'online': data['online'] ?? false,
        };
      }).toList();
      
      isLoading = false;
      
      // Set initial selected student if provided
      if (initialStudentId != null) {
        final idx = students.indexWhere((s) => s['id'] == initialStudentId);
        if (idx != -1) {
          selectedChatIndex = idx;
          selectedStudentId = initialStudentId;
        }
      }
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('❌ Error loading assigned students: $e');
      }
    }
  }

  Future<void> loadAssignedStudents({String? initialStudentId}) async {
    // Use the enhanced version with FCM token loading
    await loadAssignedStudentsWithFCM(initialStudentId: initialStudentId);
  }

  void setSearchQuery(String val) {
    searchQuery = val.trim();
    notifyListeners();
  }

  void selectChat(int index, String studentId) {
    selectedChatIndex = index;
    selectedStudentId = studentId;
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredStudents => students
      .where((student) => student['name'].toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
}
