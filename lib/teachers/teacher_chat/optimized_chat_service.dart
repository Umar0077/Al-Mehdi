import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class OptimizedChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat room ID for teacher-student conversation
  static String getChatRoomId(String teacherId, String studentId) {
    List<String> ids = [teacherId, studentId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Optimized message sending with immediate UI response
  static Future<String> sendMessageFast({
    required String receiverId,
    required String message,
    required String senderName,
    required String senderRole,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user');

    final senderId = currentUser.uid;
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();
    final tempId = '${DateTime.now().millisecondsSinceEpoch}_$senderId';

    if (kDebugMode) {
      print('🚀 Fast message sending started...');
      print('🚀 Temp ID: $tempId');
    }

    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'chatRoomId': chatRoomId,
      'read': false,
      'tempId': tempId,
    };

    // Start async operations without waiting
    _performAsyncOperations(messageData, chatRoomId, message, timestamp, senderId, senderName, receiverId, senderRole);

    return tempId; // Return immediately for UI updates
  }

  // Perform database and notification operations asynchronously
  static Future<void> _performAsyncOperations(
    Map<String, dynamic> messageData,
    String chatRoomId,
    String message,
    FieldValue timestamp,
    String senderId,
    String senderName,
    String receiverId,
    String senderRole,
  ) async {
    try {
      // Batch operations for better performance
      final batch = _firestore.batch();

      // Add message
      final messageRef = _firestore.collection('messages').doc();
      batch.set(messageRef, messageData);

      // Update chat room
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      batch.set(chatRoomRef, {
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'lastSenderId': senderId,
        'lastSenderName': senderName,
        'participants': [senderId, receiverId],
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      // Commit batch operation
      await batch.commit();

      if (kDebugMode) {
        print('✅ Fast message batch committed');
      }

      // Send notification asynchronously (fire and forget)
      NotificationService.sendChatNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        chatRoomId: chatRoomId,
      ).catchError((error) {
        if (kDebugMode) {
          print('⚠️ Notification failed: $error');
        }
      });

    } catch (e) {
      if (kDebugMode) {
        print('❌ Fast message error: $e');
      }
      rethrow;
    }
  }

  // Get real-time messages for a chat room
  static Stream<QuerySnapshot> getMessages(String teacherId, String studentId) {
    final chatRoomId = getChatRoomId(teacherId, studentId);
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      if (kDebugMode) {
        print('✅ Marked ${unreadMessages.docs.length} messages as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking messages as read: $e');
      }
    }
  }

  // Send FCM notifications in parallel
  static Future<void> sendFCMNotificationsFast({
    required List<String> tokens,
    required String title,
    required String body,
  }) async {
    if (tokens.isEmpty) return;

    try {
      final futures = tokens
          .where((token) => token.isNotEmpty)
          .map((token) => NotificationService.sendFCMNotification(
                title: title,
                body: body,
                token: token,
              ));

      // Send all notifications in parallel
      await Future.wait(futures, eagerError: false);

      if (kDebugMode) {
        print('✅ Sent ${tokens.length} FCM notifications in parallel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Some FCM notifications failed: $e');
      }
    }
  }
}
