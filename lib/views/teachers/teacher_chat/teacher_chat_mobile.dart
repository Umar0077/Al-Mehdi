import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/teachers/chats.dart';
import '../../../constants/colors.dart';
import '../../../providers/teachers/chat/teacher_chat_mobile_provider.dart';
import '../../../services/chat_service.dart';

class TeacherChatScreenMobile extends StatelessWidget {
  const TeacherChatScreenMobile({super.key});

  String _formatTime(Timestamp? timestamp) {
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherChatMobileProvider(),
      child: Consumer<TeacherChatMobileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Chats',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
            ),
            body:
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                    ? Center(child: Text('Error: ${provider.error}'))
                    : provider.students.isEmpty
                    ? const Center(
                      child: Text(
                        'No assigned students found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: provider.students.length,
                      itemBuilder: (context, index) {
                        final student = provider.students[index].data();
                        final studentName = student['fullName'] ?? 'Student';
                        final studentProfilePicture =
                            student['profilePictureUrl'] ?? '';
                        final List<dynamic> fcmToken =
                            student['fcmTokens'] != null
                                ? List<dynamic>.from(student['fcmTokens'])
                                : [];

                        final studentId = provider.students[index].id;

                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('chatRooms')
                                  .where(
                                    'participants',
                                    arrayContains: studentId,
                                  )
                                  .orderBy('updatedAt', descending: true)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, chatSnapshot) {
                            String lastMessage = 'Click to start chatting';
                            String timeText = 'Now';
                            if (chatSnapshot.hasData &&
                                chatSnapshot.data!.docs.isNotEmpty) {
                              final chatData =
                                  chatSnapshot.data!.docs.first.data()
                                      as Map<String, dynamic>;
                              lastMessage =
                                  chatData['lastMessage'] ??
                                  'Click to start chatting';
                              final lastMessageTime =
                                  chatData['lastMessageTime'] as Timestamp?;
                              timeText = _formatTime(lastMessageTime);
                            }
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final teacherId = currentUser?.uid;
                            final chatRoomId =
                                (teacherId != null)
                                    ? ChatService.getChatRoomId(
                                      teacherId,
                                      studentId,
                                    )
                                    : null;
                            return StreamBuilder<QuerySnapshot>(
                              stream:
                                  chatRoomId != null && teacherId != null
                                      ? FirebaseFirestore.instance
                                          .collection('messages')
                                          .where(
                                            'chatRoomId',
                                            isEqualTo: chatRoomId,
                                          )
                                          .where(
                                            'receiverId',
                                            isEqualTo: teacherId,
                                          )
                                          .where('read', isEqualTo: false)
                                          .snapshots()
                                      : const Stream.empty(),
                              builder: (context, unreadSnapshot) {
                                final unreadCount =
                                    unreadSnapshot.hasData
                                        ? unreadSnapshot.data!.docs.length
                                        : 0;
                                return ChatListTile(
                                  avatar:
                                      studentProfilePicture, // Will be empty string if no profile picture
                                  name: studentName,
                                  message: lastMessage,
                                  time: timeText,
                                  selected: false,
                                  unreadCount: unreadCount,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (
                                              context,
                                            ) => StudentChatConversationScreen(
                                              chat: {
                                                'avatar':
                                                    studentProfilePicture, // Will be empty string if no profile picture
                                                'name': studentName,
                                                'online': true,
                                                'studentId': studentId,
                                                'fcmToken': fcmToken,
                                              },
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            // bottomNavigationBar: buildBottomNavigationBar(context, 2),
          );
        },
      ),
    );
  }
}

class StudentChatConversationScreen extends StatelessWidget {
  final Map<String, dynamic> chat;
  const StudentChatConversationScreen({required this.chat, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  chat['avatar'].isNotEmpty
                      ? NetworkImage(chat['avatar'])
                      : null,
              backgroundColor: chat['avatar'].isNotEmpty ? null : Colors.green,
              radius: 18,
              child:
                  chat['avatar'].isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                chat['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (chat['online'])
              const Text(
                'Online',
                style: TextStyle(
                  color: appGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ChatConversation(chat: chat, showHeader: false),
        ),
      ),
    );
  }
}
