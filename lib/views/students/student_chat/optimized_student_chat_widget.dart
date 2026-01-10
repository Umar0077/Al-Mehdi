import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/chat/student_chat_mobile_provider.dart';
import '../../../services/chat_service.dart';

class OptimizedStudentChatWidget extends StatefulWidget {
  final Map<String, dynamic> chat;
  final bool showHeader;

  const OptimizedStudentChatWidget({
    super.key,
    required this.chat,
    this.showHeader = true,
  });

  @override
  State<OptimizedStudentChatWidget> createState() =>
      _OptimizedStudentChatWidgetState();
}

class _OptimizedStudentChatWidgetState
    extends State<OptimizedStudentChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Mark messages as read when chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    final teacherId = widget.chat['teacherId'];
    if (teacherId != null && currentUserId != null) {
      final chatRoomId = ChatService.getChatRoomId(currentUserId!, teacherId);
      await ChatService.markMessagesAsRead(chatRoomId, currentUserId!);
    }
  }

  void _sendMessageFast() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final provider = Provider.of<StudentChatMobileProvider>(
      context,
      listen: false,
    );

    // Clear input immediately for better UX
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
      print('📤 Student sending message optimistically: $message');
    }

    try {
      // Use the provider's optimized sending method
      await provider.sendMessageWithStudentInfo(message);
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
              _messageController.text = message;
            },
          ),
        ),
      );
    }
  }

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

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required String time,
    String? status, // For optimistic messages
    String? tempId, // For retry functionality
  }) {
    Color meColor =
        Theme.of(context).brightness == Brightness.dark
            ? appGreen
            : appLightGreen;

    Color fromColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade200;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? meColor : fromColor,
          borderRadius: BorderRadius.circular(12),
          border:
              status == 'failed'
                  ? Border.all(color: Colors.red, width: 1)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(message, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (isMe && status != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'sending') ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 4),
                    const Text('Sending...', style: TextStyle(fontSize: 10)),
                  ] else if (status == 'sent') ...[
                    const Icon(Icons.check, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Sent', style: TextStyle(fontSize: 10)),
                  ] else if (status == 'failed' && tempId != null) ...[
                    const Icon(
                      Icons.error_outline,
                      size: 12,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        final provider = Provider.of<StudentChatMobileProvider>(
                          context,
                          listen: false,
                        );
                        await provider.retryMessage(tempId);
                      },
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = widget.chat['teacherId'];

    if (teacherId == null || currentUserId == null) {
      return const Center(child: Text('Unable to load chat'));
    }

    return Consumer<StudentChatMobileProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            if (widget.showHeader)
              // Chat header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFE5EAF1), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          (widget.chat['avatar'] ?? '').isNotEmpty
                              ? NetworkImage(widget.chat['avatar'] ?? '')
                              : null,
                      backgroundColor:
                          (widget.chat['avatar'] ?? '').isNotEmpty
                              ? null
                              : Colors.green,
                      radius: 18,
                      child:
                          (widget.chat['avatar'] ?? '').isEmpty
                              ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.chat['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.chat['online'] == true)
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
                stream: ChatService.getMessages(currentUserId!, teacherId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<Widget> messageWidgets = [];

                  // Add Firestore messages
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final messages = snapshot.data!.docs;
                    final sortedMessages = [...messages];
                    sortedMessages.sort((a, b) {
                      final aTime = a['timestamp'] as Timestamp?;
                      final bTime = b['timestamp'] as Timestamp?;
                      return (aTime?.toDate() ?? DateTime(1970)).compareTo(
                        bTime?.toDate() ?? DateTime(1970),
                      );
                    });

                    for (var message in sortedMessages) {
                      final msg = message.data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == currentUserId;

                      messageWidgets.add(
                        _buildMessageBubble(
                          message: msg['message'] ?? '',
                          isMe: isMe,
                          time: _formatTime(msg['timestamp'] as Timestamp?),
                        ),
                      );
                    }
                  }

                  // Add local optimistic messages
                  for (var localMessage in provider.localMessages) {
                    final tempId = localMessage['tempId'] as String;
                    final status = provider.messageStatus[tempId];

                    messageWidgets.add(
                      _buildMessageBubble(
                        message: localMessage['message'] ?? '',
                        isMe: true,
                        time: _formatTime(
                          localMessage['timestamp'] as Timestamp?,
                        ),
                        status: status,
                        tempId: tempId,
                      ),
                    );
                  }

                  if (messageWidgets.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Auto-scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 5,
                    ),
                    children: messageWidgets,
                  );
                },
              ),
            ),
            // Message input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE5EAF1), width: 1),
                ),
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
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 0,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessageFast(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: provider.isSending ? Colors.grey : appGreen,
                    ),
                    onPressed: provider.isSending ? null : _sendMessageFast,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Enhanced Student Chat Conversation Screen
class OptimizedStudentChatConversationScreen extends StatelessWidget {
  final Map<String, dynamic> chat;

  const OptimizedStudentChatConversationScreen({required this.chat, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentChatMobileProvider>(
      create: (_) => StudentChatMobileProvider(),
      child: Scaffold(
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
                    (chat['avatar'] ?? '').isNotEmpty
                        ? NetworkImage(chat['avatar'] ?? '')
                        : null,
                backgroundColor:
                    (chat['avatar'] ?? '').isNotEmpty ? null : Colors.green,
                radius: 18,
                child:
                    (chat['avatar'] ?? '').isEmpty
                        ? Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  chat['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (chat['online'] == true)
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
        body: OptimizedStudentChatWidget(chat: chat, showHeader: false),
      ),
    );
  }
}
