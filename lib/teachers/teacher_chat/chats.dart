import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/colors.dart';
import '../../services/chat_service.dart';
import 'package:flutter/foundation.dart';

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
    bool isLightTheme = Theme.of(context).brightness == Brightness.light;
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

class ChatConversation extends StatefulWidget {
  final Map<String, dynamic> chat;
  final bool showHeader;
  const ChatConversation({
    super.key,
    required this.chat,
    this.showHeader = true,
  });

  @override
  State<ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? currentUserId;
  String? currentUserName;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _getCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });

      if (kDebugMode) {
        print('🔍 Getting user info for: ${user.uid}');
      }

      // Check if current user is a teacher
      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(user.uid)
              .get();

      if (teacherDoc.exists) {
        setState(() {
          currentUserName = teacherDoc.data()?['fullName'] ?? 'Teacher';
          currentUserRole = 'teacher';
        });
        if (kDebugMode) {
          print('👨‍🏫 User is a teacher: $currentUserName');
        }
      } else {
        // Check if current user is a student
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(user.uid)
                .get();

        if (studentDoc.exists) {
          setState(() {
            currentUserName = studentDoc.data()?['fullName'] ?? 'Student';
            currentUserRole = 'student';
          });
          if (kDebugMode) {
            print('👨‍🎓 User is a student: $currentUserName');
          }
        } else {
          if (kDebugMode) {
            print('❌ User not found in teachers or students collection');
          }
        }
      }
    } else {
      if (kDebugMode) {
        print('❌ No current user found');
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    final receiverId = widget.chat['studentId'] ?? widget.chat['teacherId'];
    if (receiverId != null && currentUserId != null) {
      final chatRoomId = ChatService.getChatRoomId(currentUserId!, receiverId);
      await ChatService.markMessagesAsRead(chatRoomId, currentUserId!);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final receiverId = widget.chat['studentId'] ?? widget.chat['teacherId'];

    if (receiverId == null || currentUserName == null || currentUserRole == null) {
      if (kDebugMode) {
        print('❌ Missing required data for sending message');
      }
      return;
    }

    // Clear input immediately for better UX
    final messageToSend = message;
    _messageController.clear();

    // Scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    if (kDebugMode) {
      print('📤 Sending message optimistically...');
      print('📤 Receiver ID: $receiverId');
      print('📤 Message: $messageToSend');
    }

    try {
      // Use optimistic sending method for faster UI response
      await ChatService.sendMessageOptimistic(
        receiverId: receiverId,
        message: messageToSend,
        senderName: currentUserName!,
        senderRole: currentUserRole!,
      );

      // Handle FCM notifications asynchronously (don't wait)
      _sendFCMNotificationsAsync(messageToSend);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      
      // Show error and restore message for retry
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _messageController.text = messageToSend;
            },
          ),
        ),
      );
    }
  }

  // Send FCM notifications asynchronously without blocking UI
  void _sendFCMNotificationsAsync(String message) async {
    try {
      if (widget.chat['fcmToken'] != null) {
        final dynamic tokens = widget.chat['fcmToken'];
        final List<Future> notificationFutures = [];

        if (tokens is List) {
          // Send to multiple tokens in parallel
          for (var token in tokens) {
            if (token != null && token.toString().isNotEmpty) {
              notificationFutures.add(
                NotificationService.sendFCMNotification(
                  title: 'New Message',
                  body: "You have a new message from $currentUserName",
                  token: token.toString(),
                )
              );
            }
          }
        } else if (tokens is String && tokens.isNotEmpty) {
          notificationFutures.add(
            NotificationService.sendFCMNotification(
              title: 'New Message',
              body: "You have a new message from $currentUserName",
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
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM notification error: $e');
      }
    }
  }

  // Original method for backward compatibility
  // Removed - using optimized _sendMessage() method instead

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
    Color meColor =
        Theme.of(context).brightness == Brightness.dark
            ? appGreen // Dark theme
            : appLightGreen; // Light theme

    Color fromColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors
                .grey
                .shade800 // Dark theme
            : Colors.grey.shade200; // Light theme

    final receiverId = widget.chat['studentId'] ?? widget.chat['teacherId'];
    final currentUserId = this.currentUserId;

    if (receiverId == null || currentUserId == null) {
      return const Center(child: Text('Unable to load chat'));
    }

    return Column(
      children: [
        if (widget.showHeader)
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5EAF1), width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.chat['avatar'].isNotEmpty ? NetworkImage(widget.chat['avatar']) : null,
                  backgroundColor: widget.chat['avatar'].isNotEmpty ? null : Colors.green,
                  radius: 18,
                  child: widget.chat['avatar'].isEmpty ? Icon(Icons.person, color: Colors.white, size: 20) : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.chat['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.chat['online'])
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
        // Chat messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ChatService.getMessages(currentUserId, receiverId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final messages = snapshot.data!.docs;
              // Sort messages in ascending order by timestamp (oldest to newest)
              final sortedMessages = [...messages];
              sortedMessages.sort((a, b) {
                final aTime = a['timestamp'] as Timestamp?;
                final bTime = b['timestamp'] as Timestamp?;
                return (aTime?.toDate() ?? DateTime(1970)).compareTo(bTime?.toDate() ?? DateTime(1970));
              });
              
              // Scroll to the bottom after data is loaded to show the latest messages
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              // We now handle auto-scrolling after sorting messages

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 5,
                ),
                reverse: false, // Show oldest at top, newest at bottom
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final msg = sortedMessages[index].data() as Map<String, dynamic>;
                  final isMe = msg['senderId'] == currentUserId;
                  final messageText = msg['message'] ?? '';
                  final timestamp = msg['timestamp'] as Timestamp?;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? meColor : fromColor,
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
                            style: TextStyle(fontSize: 12),
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
        // Message input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Color(0xFFE5EAF1), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  cursorColor: appGreen,
                  decoration: InputDecoration(
                    hintText: 'Write your message...',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey, // Grey outline color
                        width: 1.0, // Adjust thickness as needed
                      ), // No focus border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey, // Grey outline color
                        width: 1.0, // Adjust thickness as needed
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.send, color: appGreen),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      body: ChatConversation(chat: chat, showHeader: false),
    );
  }
}
