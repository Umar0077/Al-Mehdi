import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';

class ChatListTile extends StatelessWidget {
  final String avatar;
  final String name;
  final String message;
  final String time;
  final bool selected;
  final VoidCallback onTap;
  final int unreadCount;

  const ChatListTile({
    super.key,
    required this.avatar,
    required this.name,
    required this.message,
    required this.time,
    required this.selected,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final selectedTextColor =
        selected
            ? (isLightTheme ? Colors.black : Colors.black)
            : (isLightTheme ? Colors.black : Colors.white);
    final selectedColor =
        selected ? const Color(0xFFe5faf3) : Colors.transparent;
    return Container(
      decoration: BoxDecoration(
        color: selectedColor,
        borderRadius: BorderRadius.circular(selected ? 10 : 0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          backgroundColor: avatar.isNotEmpty ? null : Colors.green,
          radius: 22,
          child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white, size: 24) : null,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selectedTextColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: selectedTextColor),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 13, color: selectedTextColor),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: appGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = 'currentUserId'; // Replace with actual current user ID

  void _scrollToBottom(int messageCount) {
    if (_scrollController.hasClients && messageCount > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats') // Change to your collection path
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final sortedMessages = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          // Scroll to bottom after messages are loaded (with delay for layout)
          _scrollToBottom(sortedMessages.length);

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 5,
            ),
            reverse: false, // WhatsApp style: oldest at top, newest at bottom
            itemCount: sortedMessages.length,
            itemBuilder: (context, index) {
              final msg = sortedMessages[index];
              final isMe = msg['senderId'] == currentUserId;
              final messageText = msg['message'] ?? '';
              final timestamp = msg['timestamp'] as Timestamp?;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(
                    top: 8,
                    bottom: 8,
                    left: isMe ? 50 : 0,
                    right: isMe ? 0 : 50,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? appGreen : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        timestamp != null
                            ? DateFormat('hh:mm a').format(timestamp.toDate())
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
