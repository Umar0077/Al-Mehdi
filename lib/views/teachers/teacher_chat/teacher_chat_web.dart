import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/teachers/chats.dart';
import '../../../providers/teachers/teacher_chat_web_provider.dart';
import '../../../services/chat_service.dart';
import 'optimized_teacher_chat_web_widget.dart';

class TeacherChatScreenWeb extends StatelessWidget {
  final String? initialStudentId;
  const TeacherChatScreenWeb({super.key, this.initialStudentId});

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
      create:
          (_) =>
              TeacherChatWebProvider()
                ..loadAssignedStudents(initialStudentId: initialStudentId),
      child: Consumer<TeacherChatWebProvider>(
        builder: (context, provider, _) {
          final filteredStudents = provider.filteredStudents;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                // Sidebar
                // Sidebar(selectedIndex: 3),
                // Chat list
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      right: BorderSide(color: Color(0xFFE5EAF1), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 33,
                          vertical: 18,
                        ),
                        child: const Text(
                          'Chats',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const Divider(),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          onChanged: provider.setSearchQuery,
                          cursorColor: appGreen,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey, // Grey outline color
                                width: 1.0, // Adjust thickness as needed
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey, // Grey outline color
                                width: 1.0, // Adjust thickness as needed
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child:
                            provider.isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : provider.students.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No assigned students found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    final teacherId = currentUser?.uid;
                                    final chatRoomId =
                                        (teacherId != null &&
                                                student['id'] != null)
                                            ? ChatService.getChatRoomId(
                                              teacherId,
                                              student['id'],
                                            )
                                            : null;
                                    return StreamBuilder<QuerySnapshot>(
                                      stream:
                                          chatRoomId != null &&
                                                  teacherId != null
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
                                                  .where(
                                                    'read',
                                                    isEqualTo: false,
                                                  )
                                                  .snapshots()
                                              : const Stream.empty(),
                                      builder: (context, unreadSnapshot) {
                                        final unreadCount =
                                            unreadSnapshot.hasData
                                                ? unreadSnapshot
                                                    .data!
                                                    .docs
                                                    .length
                                                : 0;
                                        return StreamBuilder<QuerySnapshot>(
                                          stream:
                                              FirebaseFirestore.instance
                                                  .collection('chatRooms')
                                                  .where(
                                                    'participants',
                                                    arrayContains:
                                                        student['id'],
                                                  )
                                                  .orderBy(
                                                    'updatedAt',
                                                    descending: true,
                                                  )
                                                  .limit(1)
                                                  .snapshots(),
                                          builder: (context, chatSnapshot) {
                                            String lastMessage =
                                                'Click to start chatting';
                                            String timeText = 'Now';
                                            if (chatSnapshot.hasData &&
                                                chatSnapshot
                                                    .data!
                                                    .docs
                                                    .isNotEmpty) {
                                              final chatData =
                                                  chatSnapshot.data!.docs.first
                                                          .data()
                                                      as Map<String, dynamic>;
                                              lastMessage =
                                                  chatData['lastMessage'] ??
                                                  'Click to start chatting';
                                              final lastMessageTime =
                                                  chatData['lastMessageTime']
                                                      as Timestamp?;
                                              timeText = _formatTime(
                                                lastMessageTime,
                                              );
                                            }
                                            return ChatListTile(
                                              avatar: student['avatar'],
                                              name: student['name'],
                                              message: lastMessage,
                                              time: timeText,
                                              selected:
                                                  provider.selectedChatIndex ==
                                                  index,
                                              unreadCount: unreadCount,
                                              onTap:
                                                  () => provider.selectChat(
                                                    index,
                                                    student['id'],
                                                  ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                // Chat conversation or empty area
                Expanded(
                  child:
                      provider.selectedChatIndex == null
                          ? const Center(
                            child: Text(
                              'Select a student to start messaging',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                          : provider.students.isEmpty
                          ? const Center(
                            child: Text(
                              'No assigned students found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : provider.selectedChatIndex! >=
                              provider.students.length
                          ? const Center(child: Text('Student not found'))
                          : OptimizedTeacherChatWebWidget(
                            chat: {
                              'avatar':
                                  provider.students[provider
                                      .selectedChatIndex!]['avatar'],
                              'name':
                                  provider.students[provider
                                      .selectedChatIndex!]['name'],
                              'online':
                                  provider.students[provider
                                      .selectedChatIndex!]['online'] ??
                                  true,
                              'studentId':
                                  provider.students[provider
                                      .selectedChatIndex!]['id'],
                              'fcmTokens':
                                  provider.students[provider
                                      .selectedChatIndex!]['fcmTokens'],
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
