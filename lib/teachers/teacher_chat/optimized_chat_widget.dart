import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/colors.dart';
import 'optimized_chat_service.dart';
import 'package:flutter/foundation.dart';

class OptimizedChatConversation extends StatefulWidget {
  final Map<String, dynamic> chat;
  final bool showHeader;
  
  const OptimizedChatConversation({
    super.key,
    required this.chat,
    this.showHeader = true,
  });

  @override
  State<OptimizedChatConversation> createState() => _OptimizedChatConversationState();
}

class _OptimizedChatConversationState extends State<OptimizedChatConversation> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  String? currentUserId;
  String? currentUserName;
  String? currentUserRole;
  
  // Optimistic messages for instant UI updates
  final List<Map<String, dynamic>> _optimisticMessages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
    
    // Auto-focus on text field for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });

      // Check if current user is a teacher
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          currentUserName = teacherDoc.data()?['fullName'] ?? 'Teacher';
          currentUserRole = 'teacher';
        });
      } else {
        // Check if current user is a student
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          setState(() {
            currentUserName = studentDoc.data()?['fullName'] ?? 'Student';
            currentUserRole = 'student';
          });
        }
      }
    }
  }

  Future<void> _sendMessageFast() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final message = _messageController.text.trim();
    final receiverId = widget.chat['studentId'] ?? widget.chat['teacherId'];

    if (receiverId == null || currentUserName == null || currentUserRole == null) {
      _showError('Missing required information');
      return;
    }

    setState(() {
      _isSending = true;
    });

    // Create optimistic message for immediate UI update
    final tempId = '${DateTime.now().millisecondsSinceEpoch}_${currentUserId}';
    final optimisticMessage = {
      'senderId': currentUserId,
      'senderName': currentUserName!,
      'senderRole': currentUserRole!,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.now(),
      'tempId': tempId,
      'optimistic': true,
      'sending': true,
    };

    // Clear input immediately and show optimistic message
    _messageController.clear();
    setState(() {
      _optimisticMessages.add(optimisticMessage);
    });

    // Auto-scroll to bottom
    _scrollToBottom();

    try {
      // Send message using optimized service
      await OptimizedChatService.sendMessageFast(
        receiverId: receiverId,
        message: message,
        senderName: currentUserName!,
        senderRole: currentUserRole!,
      );

      // Update optimistic message status
      setState(() {
        final index = _optimisticMessages.indexWhere((msg) => msg['tempId'] == tempId);
        if (index != -1) {
          _optimisticMessages[index] = {
            ..._optimisticMessages[index],
            'sending': false,
            'sent': true,
          };
        }
      });

      // Send FCM notifications asynchronously
      _sendFCMNotifications(message);

      if (kDebugMode) {
        print('✅ Message sent successfully');
      }

    } catch (e) {
      // Handle error - mark message as failed
      setState(() {
        final index = _optimisticMessages.indexWhere((msg) => msg['tempId'] == tempId);
        if (index != -1) {
          _optimisticMessages[index] = {
            ..._optimisticMessages[index],
            'sending': false,
            'failed': true,
          };
        }
      });

      _showError('Failed to send message', action: () {
        // Retry functionality
        _messageController.text = message;
        setState(() {
          _optimisticMessages.removeWhere((msg) => msg['tempId'] == tempId);
        });
      });

      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _sendFCMNotifications(String message) async {
    try {
      if (widget.chat['fcmToken'] != null) {
        final dynamic tokens = widget.chat['fcmToken'];
        final List<String> tokenList = [];

        if (tokens is List) {
          tokenList.addAll(tokens.where((token) => token != null).map((token) => token.toString()));
        } else if (tokens is String && tokens.isNotEmpty) {
          tokenList.add(tokens);
        }

        if (tokenList.isNotEmpty) {
          // Send notifications in parallel for better performance
          OptimizedChatService.sendFCMNotificationsFast(
            tokens: tokenList,
            title: 'New Message',
            body: 'You have a new message from $currentUserName',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM notification error: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message, {VoidCallback? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: action != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: action,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiverId = widget.chat['studentId'] ?? widget.chat['teacherId'];
    
    if (currentUserId == null || receiverId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showHeader ? _buildAppBar() : null,
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessagesList(),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.chat['avatar'] ?? ''),
            radius: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.chat['name'] ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: appGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: OptimizedChatService.getMessages(currentUserId!, widget.chat['studentId'] ?? widget.chat['teacherId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (_optimisticMessages.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet. Start the conversation!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
        }

        // Combine real messages with optimistic messages
        final realMessages = snapshot.data?.docs ?? [];
        final allMessages = <Widget>[];

        // Add real messages
        for (var doc in realMessages) {
          final data = doc.data() as Map<String, dynamic>;
          allMessages.add(_buildMessageBubble(data, false));
        }

        // Add optimistic messages (that haven't been persisted yet)
        for (var optimisticMsg in _optimisticMessages) {
          // Only show if not already in real messages
          final isAlreadyReal = realMessages.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tempId'] == optimisticMsg['tempId'];
          });
          
          if (!isAlreadyReal) {
            allMessages.add(_buildMessageBubble(optimisticMsg, true));
          }
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: allMessages.length,
          itemBuilder: (context, index) => allMessages[index],
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isOptimistic) {
    final isCurrentUser = data['senderId'] == currentUserId;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeText = timestamp != null 
        ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : 'Now';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.chat['avatar'] ?? ''),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? appGreen : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['message'] ?? '',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isCurrentUser && isOptimistic) ...[
                        const SizedBox(width: 4),
                        if (data['sending'] == true)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          )
                        else if (data['failed'] == true)
                          const Icon(
                            Icons.error_outline,
                            size: 12,
                            color: Colors.redAccent,
                          )
                        else if (data['sent'] == true)
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white70,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=$currentUserId'),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessageFast(),
              enabled: !_isSending,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: appGreen,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _isSending ? null : _sendMessageFast,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
