import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherChatMobileProvider extends ChangeNotifier {
  int? selectedChatIndex;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> students = [];
  bool isLoading = true;
  String? error;
  
  // Message state management for fast UI updates
  Map<String, List<Map<String, dynamic>>> _localMessages = {};
  Map<String, bool> _sendingMessages = {};

  TeacherChatMobileProvider() {
    loadAssignedStudents();
  }

  List<Map<String, dynamic>> getLocalMessages(String chatRoomId) {
    return _localMessages[chatRoomId] ?? [];
  }

  bool isSendingMessage(String chatRoomId) {
    return _sendingMessages[chatRoomId] ?? false;
  }

  // Add message optimistically to local state
  void addOptimisticMessage(String chatRoomId, Map<String, dynamic> message) {
    if (_localMessages[chatRoomId] == null) {
      _localMessages[chatRoomId] = [];
    }
    _localMessages[chatRoomId]!.add(message);
    notifyListeners();
  }

  // Update message status (e.g., from sending to sent)
  void updateMessageStatus(String chatRoomId, String tempId, Map<String, dynamic> updates) {
    if (_localMessages[chatRoomId] != null) {
      final messageIndex = _localMessages[chatRoomId]!.indexWhere(
        (msg) => msg['tempId'] == tempId,
      );
      if (messageIndex != -1) {
        _localMessages[chatRoomId]![messageIndex] = {
          ..._localMessages[chatRoomId]![messageIndex],
          ...updates,
        };
        notifyListeners();
      }
    }
  }

  // Set sending state for a chat room
  void setSendingMessage(String chatRoomId, bool sending) {
    _sendingMessages[chatRoomId] = sending;
    notifyListeners();
  }

  // Clear local messages when real messages are loaded
  void clearLocalMessages(String chatRoomId) {
    _localMessages[chatRoomId] = [];
    notifyListeners();
  }

  Future<void> loadAssignedStudents() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('assignedTeacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      students = studentsSnapshot.docs;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void selectChat(int index) {
    selectedChatIndex = index;
    notifyListeners();
  }
}
