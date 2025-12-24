import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../services/notification_service.dart';
import 'teacher_notifications_web_provider.dart';

class TeacherNotificationWebView extends StatelessWidget {
  const TeacherNotificationWebView({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.message;
      case 'class':
        return Icons.calendar_today;
      case 'system':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherNotificationWebProvider(),
      child: Consumer<TeacherNotificationWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 16),
                    _filterAndSearch(context, provider),
                    const SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: NotificationService.getNotificationsStream(),
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
                                'No notifications yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }
                          final notifications = snapshot.data!.docs;
                          List<QueryDocumentSnapshot> filteredNotifications = notifications;
                          // Apply filter
                          if (provider.filterValue == 'Read') {
                            filteredNotifications = notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == true).toList();
                          } else if (provider.filterValue == 'Unread') {
                            filteredNotifications = notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == false).toList();
                          }
                          // Apply search
                          if (provider.searchController.text.isNotEmpty) {
                            filteredNotifications = filteredNotifications.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data['title']?.toString().toLowerCase().contains(provider.searchController.text.toLowerCase()) ?? false) ||
                                  (data['body']?.toString().toLowerCase().contains(provider.searchController.text.toLowerCase()) ?? false);
                            }).toList();
                          }
                          return ListView.builder(
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final doc = filteredNotifications[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _notificationCard(context, data, doc.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _filterAndSearch(BuildContext context, TeacherNotificationWebProvider provider) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: provider.searchController,
            onChanged: (value) => provider.onSearchChanged(),
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: provider.filterValue,
          icon: const Icon(Icons.arrow_drop_down, color: appGreen),
          underline: const SizedBox(),
          items: ['All', 'Read', 'Unread'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) {
            provider.setFilterValue(val ?? 'All');
          },
        ),
      ],
    );
  }

  Widget _notificationCard(
    BuildContext context,
    Map<String, dynamic> notif,
    String notificationId,
  ) {
    final isClassNotification = notif['type'] == 'class';
    final classData = notif['classData'] as Map<String, dynamic>?;
    
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isClassNotification 
            ? BorderSide(color: appGreen.withValues(alpha: 0.3), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isClassNotification 
                      ? appGreen.withValues(alpha: 0.1)
                      : const Color(0xFFe5faf3),
                  child: Icon(_getNotificationIcon(notif['type'] ?? 'system'), color: appGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'] ?? 'Notification',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['body'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      // Show additional class details if it's a class notification
                      if (isClassNotification && classData != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (classData['studentName'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: appGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Student: ${classData['studentName']}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              if (classData['description'] != null && classData['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.description, size: 18, color: appGreen),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Description: ${classData['description']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_formatTime(notif['timestamp'] as Timestamp?), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                if (notif['read'] == false)
                  GestureDetector(
                    onTap: () => _markAsRead(notificationId),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: appGreen, size: 18),
                        SizedBox(width: 6),
                        Text('Mark as Read', style: TextStyle(color: appGreen)),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _markAsUnread(notificationId),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle_outlined, color: appGreen, size: 18),
                        SizedBox(width: 6),
                        Text('Mark as Unread', style: TextStyle(color: appGreen)),
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _deleteNotification(notificationId),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, color: appRed, size: 18),
                      SizedBox(width: 6),
                      Text('Delete', style: TextStyle(color: appRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationService.markNotificationAsRead(notificationId);
  }

  Future<void> _markAsUnread(String notificationId) async {
    await NotificationService.markNotificationAsUnread(notificationId);
  }

  Future<void> _deleteNotification(String notificationId) async {
    await NotificationService.deleteNotification(notificationId);
  }
}
