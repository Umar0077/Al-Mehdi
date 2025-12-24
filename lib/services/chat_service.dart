import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat room ID for teacher-student conversation
  static String getChatRoomId(String teacherId, String studentId) {
    // Sort IDs to ensure consistent room ID regardless of who initiates
    List<String> ids = [teacherId, studentId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message with optimistic updates
  static Future<String> sendMessageOptimistic({
    required String receiverId,
    required String message,
    required String senderName,
    required String senderRole, // 'teacher' or 'student'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user');

    final senderId = currentUser.uid;
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();
    final tempId = '${DateTime.now().millisecondsSinceEpoch}_$senderId';

    if (kDebugMode) {
      print('💬 Sending message optimistically...');
      print('💬 Temp ID: $tempId');
      print('💬 Chat Room ID: $chatRoomId');
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

    // Start asynchronous operations without waiting
    _sendMessageAsync(messageData, chatRoomId, message, timestamp, senderId, senderName, receiverId, senderRole);

    return tempId; // Return immediately for optimistic updates
  }

  // Async message sending that doesn't block UI
  static Future<void> _sendMessageAsync(
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
      // Add message to messages collection
      final docRef = await _firestore.collection('messages').add(messageData);
      
      // Update chat room in parallel
      final chatRoomUpdate = _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'lastSenderId': senderId,
        'lastSenderName': senderName,
        'participants': [senderId, receiverId],
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      // Send notification in parallel (don't wait for it)
      final notificationFuture = NotificationService.sendChatNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        chatRoomId: chatRoomId,
      );

      // Wait for critical operations only
      await Future.wait([chatRoomUpdate]);
      
      // Fire and forget notification
      notificationFuture.catchError((error) {
        if (kDebugMode) {
          print('⚠️ Notification failed: $error');
        }
      });

      if (kDebugMode) {
        print('✅ Message saved with ID: ${docRef.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in async message sending: $e');
      }
      rethrow;
    }
  }

  // Send a message (legacy method for backward compatibility)
  static Future<void> sendMessage({
    required String receiverId,
    required String message,
    required String senderName,
    required String senderRole, // 'teacher' or 'student'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.uid;
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    if (kDebugMode) {
      print('💬 Sending message...');
      print('💬 Sender ID: $senderId');
      print('💬 Sender Name: $senderName');
      print('💬 Sender Role: $senderRole');
      print('💬 Receiver ID: $receiverId');
      print('💬 Message: $message');
      print('💬 Chat Room ID: $chatRoomId');
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
    };

    // Add message to messages collection
    await _firestore.collection('messages').add(messageData);

    // Update or create chat room document
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastSenderId': senderId,
      'lastSenderName': senderName,
      'participants': [senderId, receiverId],
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    if (kDebugMode) {
      print('✅ Message saved to database');
    }

    // Send notification to receiver
    await NotificationService.sendChatNotification(
      receiverId: receiverId,
      senderName: senderName,
      message: message,
      chatRoomId: chatRoomId,
    );

    if (kDebugMode) {
      print('✅ Notification sent');
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

  // Get user's recent conversations
  static Future<List<Map<String, dynamic>>> getRecentConversations(
    String userId,
  ) async {
    final chatRoomsSnapshot =
        await _firestore
            .collection('chatRooms')
            .where('participants', arrayContains: userId)
            .orderBy('updatedAt', descending: true)
            .limit(10)
            .get();

    List<Map<String, dynamic>> conversations = [];

    for (var room in chatRoomsSnapshot.docs) {
      final roomData = room.data();
      final participants = List<String>.from(roomData['participants']);

      // Get the other participant's ID
      final otherParticipantId = participants.firstWhere((id) => id != userId);

      // Get user details
      String userName = 'Unknown';
      String userRole = 'unknown';

      // Check if it's a teacher
      final teacherDoc =
          await _firestore.collection('teachers').doc(otherParticipantId).get();
      if (teacherDoc.exists) {
        userName = teacherDoc.data()?['fullName'] ?? 'Teacher';
        userRole = 'teacher';
      } else {
        // Check if it's a student
        final studentDoc =
            await _firestore
                .collection('students')
                .doc(otherParticipantId)
                .get();
        if (studentDoc.exists) {
          userName = studentDoc.data()?['fullName'] ?? 'Student';
          userRole = 'student';
        }
      }

      conversations.add({
        'chatRoomId': room.id,
        'userId': otherParticipantId,
        'userName': userName,
        'userRole': userRole,
        'lastMessage': roomData['lastMessage'] ?? '',
        'lastMessageTime': roomData['lastMessageTime'],
        'avatar': 'https://i.pravatar.cc/100?u=$otherParticipantId',
      });
    }

    return conversations;
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
    String chatRoomId,
    String userId,
  ) async {
    final messagesSnapshot =
        await _firestore
            .collection('messages')
            .where('chatRoomId', isEqualTo: chatRoomId)
            .where('receiverId', isEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // Get unread message count
  static Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
