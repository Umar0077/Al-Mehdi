import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../services/notification_service.dart';
import 'teacher_notifications_mobile_provider.dart';

class TeacherNotificationMobileView extends StatelessWidget {
  const TeacherNotificationMobileView({super.key});

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
      create: (_) => TeacherNotificationMobileProvider(),
      child: Consumer<TeacherNotificationMobileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: provider.filterValue,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: appGreen,
                              ),
                              underline: const SizedBox(),
                              items: ['All', 'Read', 'Unread']
                                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) provider.setFilterValue(val);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search bar
                    TextField(
                      controller: provider.searchController,
                      onChanged: (_) => provider.onSearchChanged(),
                      decoration: InputDecoration(
                        hintText: 'Search notifications...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notifications
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

                          return ListView.separated(
                            itemCount: filteredNotifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final doc = filteredNotifications[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildNotificationCard(context, data, doc.id);
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

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notif, String notificationId) {
    final isClassNotification = notif['type'] == 'class';
    final classData = notif['classData'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isClassNotification 
            ? Border.all(color: appGreen.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isClassNotification 
                    ? appGreen.withOpacity(0.1)
                    : const Color(0xFFe5faf3),
                child: Icon(
                  _getNotificationIcon(notif['type'] ?? 'system'),
                  color: appGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'] ?? 'Notification',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'] ?? '',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show additional class details if it's a class notification
                    if (isClassNotification && classData != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (classData['studentName'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: appGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Student: ${classData['studentName']}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            if (classData['description'] != null && classData['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.description, size: 16, color: appGreen),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Description: ${classData['description']}',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
              if (notif['read'] == false)
                const Icon(Icons.circle, color: appGreen, size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatTime(notif['timestamp'] as Timestamp?),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              if (notif['read'] == false)
                GestureDetector(
                  onTap: () => _markAsRead(context, notificationId),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: appGreen, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Mark as Read',
                        style: TextStyle(fontSize: 12, color: appGreen),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _markAsUnread(context, notificationId),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle_outlined, color: appGreen, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Mark as Unread',
                        style: TextStyle(fontSize: 12, color: appGreen),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _deleteNotification(context, notificationId),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete, color: appRed, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Delete',
                      style: TextStyle(fontSize: 12, color: appRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, String notificationId) async {
    try {
      await NotificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking as read: $e')));
    }
  }

  Future<void> _markAsUnread(BuildContext context, String notificationId) async {
    try {
      await NotificationService.markNotificationAsUnread(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking as unread: $e')));
    }
  }

  Future<void> _deleteNotification(BuildContext context, String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }
}
