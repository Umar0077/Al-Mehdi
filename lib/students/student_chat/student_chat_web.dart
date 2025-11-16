import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'chats.dart';
import 'student_chat_web_provider.dart';
import 'optimized_student_chat_web_widget.dart';

class StudentChatWebView extends StatelessWidget {
  final String? initialTeacherId;
  const StudentChatWebView({super.key, this.initialTeacherId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentChatWebProvider>(
      create: (_) => StudentChatWebProvider(initialTeacherId: initialTeacherId),
      child: Consumer<StudentChatWebProvider>(
        builder: (context, provider, _) {
          final searchController = TextEditingController(text: provider.searchQuery);
          searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: searchController.text.length),
          );
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: const Border(
                      right: BorderSide(color: Color(0xFFE5EAF1), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Chats',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: provider.setSearchQuery,
                          cursorColor: appGreen,
                          decoration: InputDecoration(
                            hintText: 'Search teacher...',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.assignedTeacherId == null
                              ? const Center(
                                  child: Text(
                                    'No teacher assigned yet',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : (provider.teacherName != null &&
                                      provider.teacherName!.toLowerCase().contains(
                                            provider.searchQuery.toLowerCase(),
                                          ))
                                  ? StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('chatRooms')
                                          .where(
                                            'participants',
                                            arrayContains: provider.assignedTeacherId,
                                          )
                                          .orderBy('updatedAt', descending: true)
                                          .limit(1)
                                          .snapshots(),
                                      builder: (context, chatSnapshot) {
                                        String lastMessage = 'Click to start chatting';
                                        String timeText = 'Now';
                                        String? chatRoomId;
                                        if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
                                          final chatData = chatSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                          lastMessage = chatData['lastMessage'] ?? 'Click to start chatting';
                                          final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
                                          timeText = provider.formatTime(lastMessageTime);
                                          chatRoomId = chatSnapshot.data!.docs.first.id;
                                        }
                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        return StreamBuilder<QuerySnapshot>(
                                          stream: chatRoomId != null && currentUser != null
                                              ? FirebaseFirestore.instance
                                                  .collection('messages')
                                                  .where('chatRoomId', isEqualTo: chatRoomId)
                                                  .where('receiverId', isEqualTo: currentUser.uid)
                                                  .where('read', isEqualTo: false)
                                                  .snapshots()
                                              : const Stream.empty(),
                                          builder: (context, unreadSnapshot) {
                                            final unreadCount = unreadSnapshot.hasData ? unreadSnapshot.data!.docs.length : 0;
                                            return ChatListTile(
                                              avatar: provider.teacherAvatar ?? '',
                                              name: provider.teacherName ?? '',
                                              message: lastMessage,
                                              time: timeText,
                                              selected: provider.selectedChatIndex == 0,
                                              unreadCount: unreadCount,
                                              onTap: () {
                                                provider.selectChatIndex(0);
                                              },
                                            );
                                          },
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Text(
                                        'No teacher found',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.assignedTeacherId == null
                          ? const Center(
                              child: Text(
                                'No teacher assigned yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : provider.selectedChatIndex != 0
                              ? const Center(
                                  child: Text(
                                    'Select your teacher to start messaging',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 17,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFE5EAF1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              provider.teacherAvatar ?? '',
                                            ),
                                            radius: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            provider.teacherName ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                    Expanded(
                                      child: OptimizedStudentChatWebWidget(
                                        chat: {
                                          'avatar': provider.teacherAvatar,
                                          'name': provider.teacherName,
                                          'online': true,
                                          'teacherId': provider.assignedTeacherId,
                                          'fcmToken': provider.fcm_token,
                                        },
                                        showHeader: false,
                                      ),
                                    ),
                                  ],
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
