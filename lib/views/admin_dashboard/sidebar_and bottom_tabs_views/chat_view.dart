import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin/chat_screen_provider.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatScreenProvider(),
      child: Consumer<ChatScreenProvider>(
        builder: (context, provider, _) {
          Color dropdownColor =
              Theme.of(context).brightness == Brightness.dark
                  ? darkBackground
                  : appLightGreen;
          final filteredRooms =
              provider.chatRooms.where((room) {
                final teacherMatch =
                    provider.selectedTeacherId == null ||
                    room['teacherId'] == provider.selectedTeacherId;
                final studentMatch =
                    provider.selectedStudentId == null ||
                    room['studentId'] == provider.selectedStudentId;
                final searchMatch =
                    provider.searchTerm.isEmpty ||
                    room['studentName'].toLowerCase().contains(
                      provider.searchTerm.toLowerCase(),
                    ) ||
                    room['teacherName'].toLowerCase().contains(
                      provider.searchTerm.toLowerCase(),
                    ) ||
                    (room['lastMessage'] ?? '').toLowerCase().contains(
                      provider.searchTerm.toLowerCase(),
                    );
                return teacherMatch && studentMatch && searchMatch;
              }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Row(
                    children: [
                      // Remove AdminSidebar here
                      // Chat list
                      Container(
                        width: 340,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFE5EAF1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 33,
                                vertical: 14,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  // Dropdowns for teacher and student
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: provider.selectedTeacherId,
                                              hint: const Text(
                                                'Select Teacher',
                                              ),
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                                color: appGreen,
                                              ),
                                              style: TextStyle(
                                                color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                              ),
                                              dropdownColor: dropdownColor,
                                              items: [
                                                const DropdownMenuItem<String>(
                                                  value: null,
                                                  child: Text('Select Teacher'),
                                                ),
                                                ...(provider.selectedStudentId ==
                                                            null
                                                        ? provider.teachers
                                                        : provider
                                                            .teachersForStudent)
                                                    .map(
                                                      (t) => DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: t['id'],
                                                        child: Text(t['name']),
                                                      ),
                                                    ),
                                              ],
                                              onChanged: (val) async {
                                                provider.setSelectedTeacherId(
                                                  val,
                                                );
                                                if (val != null) {
                                                  await provider
                                                      .loadStudentsForTeacher(
                                                        val,
                                                      );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            provider
                                                        .studentsForTeacher
                                                        .isEmpty &&
                                                    provider.selectedTeacherId !=
                                                        null &&
                                                    !provider.teacherHasChats
                                                ? const Center(
                                                  child: Text(
                                                    'No students',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                                : Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<
                                                      String
                                                    >(
                                                      isExpanded: true,
                                                      value:
                                                          provider
                                                              .selectedStudentId,
                                                      hint: const Text(
                                                        'Select Student',
                                                      ),
                                                      icon: const Icon(
                                                        Icons.arrow_drop_down,
                                                        color: appGreen,
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                      ),
                                                      dropdownColor:
                                                          dropdownColor,
                                                      items: [
                                                        const DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            'Select Student',
                                                          ),
                                                        ),
                                                        ...(provider.selectedTeacherId ==
                                                                    null
                                                                ? provider
                                                                    .students
                                                                : provider
                                                                    .studentsForTeacher)
                                                            .map(
                                                              (s) =>
                                                                  DropdownMenuItem<
                                                                    String
                                                                  >(
                                                                    value:
                                                                        s['id'],
                                                                    child: Text(
                                                                      s['name'],
                                                                    ),
                                                                  ),
                                                            ),
                                                      ],
                                                      onChanged: (val) async {
                                                        provider
                                                            .setSelectedStudentId(
                                                              val,
                                                            );
                                                        if (val != null) {
                                                          await provider
                                                              .loadTeachersForStudent(
                                                                val,
                                                              );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Search bar with icon
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                provider.searchController,
                                            cursorColor: appGreen,
                                            decoration: const InputDecoration(
                                              hintText: 'Search...',
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                            ),
                                            onChanged: (val) {
                                              provider.setSearchTerm(
                                                val.trim(),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            provider.isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : Expanded(
                                  child:
                                      filteredRooms.isEmpty
                                          ? const Center(
                                            child: Text('No chats found'),
                                          )
                                          : ListView.builder(
                                            itemCount: filteredRooms.length,
                                            itemBuilder: (context, index) {
                                              final room = filteredRooms[index];
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      provider.selectedChatIndex ==
                                                              index
                                                          ? const Color(
                                                            0xFFe5faf3,
                                                          )
                                                          : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        provider.selectedChatIndex ==
                                                                index
                                                            ? 10
                                                            : 0,
                                                      ),
                                                ),
                                                child: ChatListTile(
                                                  name:
                                                      '${room['studentName']} & ${room['teacherName']}',
                                                  message: room['lastMessage'],
                                                  time:
                                                      room['lastMessageTime'] !=
                                                              null
                                                          ? provider.formatTime(
                                                            room['lastMessageTime'],
                                                          )
                                                          : '',
                                                  selected:
                                                      provider
                                                          .selectedChatIndex ==
                                                      index,
                                                  onTap:
                                                      () => provider
                                                          .setSelectedChatIndex(
                                                            index,
                                                          ),
                                                ),
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
                            provider.selectedChatIndex == null ||
                                    filteredRooms.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Select a chat to view conversation',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                                : AdminChatConversation(
                                  chatRoomId:
                                      filteredRooms[provider
                                          .selectedChatIndex!]['id'],
                                  studentName:
                                      filteredRooms[provider
                                          .selectedChatIndex!]['studentName'],
                                  teacherName:
                                      filteredRooms[provider
                                          .selectedChatIndex!]['teacherName'],
                                  studentId:
                                      filteredRooms[provider
                                          .selectedChatIndex!]['studentId'],
                                  teacherId:
                                      filteredRooms[provider
                                          .selectedChatIndex!]['teacherId'],
                                ),
                      ),
                    ],
                  ),
                );
              } else {
                // For mobile, show chat list and navigate to conversation
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: AppBar(
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'Chats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  body: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            // Teacher & Student Dropdowns side by side
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: provider.selectedTeacherId,
                                        hint: const Text('Select Teacher'),
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: appGreen,
                                        ),
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                        ),
                                        dropdownColor: dropdownColor,
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('Select Teacher'),
                                          ),
                                          ...(provider.selectedStudentId == null
                                                  ? provider.teachers
                                                  : provider.teachersForStudent)
                                              .map(
                                                (t) => DropdownMenuItem<String>(
                                                  value: t['id'],
                                                  child: Text(t['name']),
                                                ),
                                              ),
                                        ],
                                        onChanged: (val) async {
                                          provider.setSelectedTeacherId(val);
                                          if (val != null) {
                                            await provider
                                                .loadStudentsForTeacher(val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child:
                                      provider.studentsForTeacher.isEmpty &&
                                              provider.selectedTeacherId !=
                                                  null &&
                                              !provider.teacherHasChats
                                          ? const Center(
                                            child: Text(
                                              'No students',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                          : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                isExpanded: true,
                                                value:
                                                    provider.selectedStudentId,
                                                hint: const Text(
                                                  'Select Student',
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: appGreen,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                ),
                                                dropdownColor: dropdownColor,
                                                items: [
                                                  const DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: null,
                                                    child: Text(
                                                      'Select Student',
                                                    ),
                                                  ),
                                                  ...(provider.selectedTeacherId ==
                                                              null
                                                          ? provider.students
                                                          : provider
                                                              .studentsForTeacher)
                                                      .map(
                                                        (s) => DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: s['id'],
                                                          child: Text(
                                                            s['name'],
                                                          ),
                                                        ),
                                                      ),
                                                ],
                                                onChanged: (val) async {
                                                  provider.setSelectedStudentId(
                                                    val,
                                                  );
                                                  if (val != null) {
                                                    await provider
                                                        .loadTeachersForStudent(
                                                          val,
                                                        );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Search bar with icon
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(20),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: provider.searchController,
                                      cursorColor: appGreen,
                                      decoration: const InputDecoration(
                                        hintText: 'Search...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        provider.setSearchTerm(val.trim());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      provider.isLoading
                          ? const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : Expanded(
                            child:
                                filteredRooms.isEmpty
                                    ? const Center(
                                      child: Text('No chats found'),
                                    )
                                    : ListView.builder(
                                      itemCount: filteredRooms.length,
                                      itemBuilder: (context, index) {
                                        final room = filteredRooms[index];
                                        return ChatListTile(
                                          name:
                                              '${room['studentName']} & ${room['teacherName']}',
                                          message: room['lastMessage'],
                                          time:
                                              room['lastMessageTime'] != null
                                                  ? provider.formatTime(
                                                    room['lastMessageTime'],
                                                  )
                                                  : '',
                                          selected: false,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => AdminChatConversationMobile(
                                                      chatRoomId: room['id'],
                                                      studentName:
                                                          room['studentName'],
                                                      teacherName:
                                                          room['teacherName'],
                                                      studentId:
                                                          room['studentId'],
                                                      teacherId:
                                                          room['teacherId'],
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                          ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final String? avatar;
  final String name;
  final String message;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    this.avatar,
    required this.name,
    required this.message,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Material(
      color:
          selected
              ? (isLightTheme ? const Color(0xFFe5faf3) : Colors.white10)
              : Colors.transparent,
      child: ListTile(
        leading:
            avatar != null
                ? CircleAvatar(
                  backgroundImage: NetworkImage(avatar!),
                  radius: 22,
                )
                : const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 22,
                  child: Icon(Icons.person, color: Colors.white),
                ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(time, style: const TextStyle(fontSize: 13)),
        onTap: onTap,
      ),
    );
  }
}

class AdminChatConversation extends StatelessWidget {
  final String chatRoomId;
  final String studentName;
  final String teacherName;
  final String? studentId;
  final String? teacherId;
  final String? avatar;
  final bool showHeader;
  const AdminChatConversation({
    super.key,
    required this.chatRoomId,
    required this.studentName,
    required this.teacherName,
    required this.studentId,
    required this.teacherId,
    this.avatar,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    Color studentColor =
        Theme.of(context).brightness == Brightness.dark
            ? appGreen
            : appLightGreen;
    Color teacherColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : appGreen.withOpacity(0.2);
    Color otherColor = Colors.grey.shade200;
    return Column(
      children: [
        if (showHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE5EAF1), width: 1),
              ),
            ),
            child: Row(
              children: [
                avatar != null
                    ? CircleAvatar(
                      backgroundImage: NetworkImage(avatar!),
                      radius: 18,
                    )
                    : const CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$studentName & $teacherName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('messages')
                    .where('chatRoomId', isEqualTo: chatRoomId)
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No messages yet.'));
              }
              final messages = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final isStudent = msg['senderId'] == studentId;
                  final isTeacher = msg['senderId'] == teacherId;
                  final messageText = msg['message'] ?? '';
                  final timestamp = msg['timestamp'] as Timestamp?;
                  return Align(
                    alignment:
                        isStudent
                            ? Alignment.centerLeft
                            : isTeacher
                            ? Alignment.centerRight
                            : Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isStudent
                                ? studentColor
                                : isTeacher
                                ? teacherColor
                                : otherColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              messageText,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // No input box for admin (read-only)
      ],
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
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

class AdminChatConversationMobile extends StatelessWidget {
  final String chatRoomId;
  final String studentName;
  final String teacherName;
  final String? studentId;
  final String? teacherId;
  final String? avatar;
  const AdminChatConversationMobile({
    super.key,
    required this.chatRoomId,
    required this.studentName,
    required this.teacherName,
    required this.studentId,
    required this.teacherId,
    this.avatar,
  });

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
            avatar != null
                ? CircleAvatar(
                  backgroundImage: NetworkImage(avatar!),
                  radius: 18,
                )
                : const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 18,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$studentName & $teacherName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: AdminChatConversation(
        chatRoomId: chatRoomId,
        studentName: studentName,
        teacherName: teacherName,
        studentId: studentId,
        teacherId: teacherId,
        showHeader: false,
      ),
    );
  }
}
