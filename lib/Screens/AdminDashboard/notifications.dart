import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../constants/colors.dart';
import 'notifications_provider.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider()..initialize(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationsProvider>(context);
    Color dropColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Web/Desktop layout
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Row(
                children: [
                  // Left: Notifications
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14.0,
                            ),
                            child: Text(
                              'Latest updates about your classes and app.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Filter + Search
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                DropdownButton<String>(
                                  focusColor: dropColor,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: appGreen,
                                  ),
                                  underline: const SizedBox.shrink(),
                                  value: provider.filterValue,
                                  dropdownColor: dropColor,
                                  items:
                                      ['All', 'Read', 'Unread']
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) {
                                    if (val != null) provider.setFilter(val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: TextField(
                                      controller: provider.searchController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Search Notifications...',
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? darkBackground
                                                : Colors.grey[100],
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 0,
                                              horizontal: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (_) {
                                        provider.setSearchTerm(
                                            provider.searchController.text);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Notifications List (real-time)
                          Expanded(
                            child: provider.isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : provider.adminUid == null
                                    ? const Center(child: Text('Admin not found'))
                                    : StreamBuilder<QuerySnapshot>(
                                        stream: provider.notificationsStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (snapshot.hasError) {
                                            return Center(child: Text('Error:  ${snapshot.error}'));
                                          }
                                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                            return const Center(child: Text('No notifications yet'));
                                          }
                                          final notifications = snapshot.data!.docs;
                                          final filteredNotifications = provider.filterAndSearch(notifications);
                                          return ListView.builder(
                                            itemCount: filteredNotifications.length,
                                            itemBuilder: (context, index) {
                                              final doc = filteredNotifications[index];
                                              final data = doc.data() as Map<String, dynamic>;
                                              return _buildNotificationCard(context, provider, data, doc.id);
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: Filters & Stats (optional, can be kept or removed)
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(24),
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? darkBackground
                            : Colors.grey[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _filterButton(context, provider, 'Read'),
                        _filterButton(context, provider, 'Unread'),
                        const SizedBox(height: 24),
                        const Text(
                          'Preferences',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: provider.markAllAsRead,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: appGreen,
                              side: BorderSide(color: appGreen),
                            ),
                            child: const Text('Mark all as read'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: provider.deleteAll,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: appGreen,
                              side: BorderSide(color: appGreen),
                            ),
                            child: const Text('Delete all'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.all(24),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? darkBackground
                                    : Colors.grey[50],
                            child: StreamBuilder<QuerySnapshot>(
                              stream: provider.notificationsStream,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }
                                final notifications = snapshot.data!.docs;
                                final unreadCount = provider.countUnread(notifications);
                                final readCount = provider.countRead(notifications);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stats',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _statRow(Icons.error, '$unreadCount Unread', appGreen),
                                    _statRow(Icons.check_circle, '$readCount Read', appGreen),
                                    _statRow(Icons.notifications, '${notifications.length} Total', appGreen),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              focusColor: dropColor,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: appGreen,
                              ),
                              value: provider.filterValue,
                              underline: const SizedBox(),
                              dropdownColor: dropColor,
                              items:
                                  ['All', 'Read', 'Unread']
                                      .map(
                                        (val) => DropdownMenuItem(
                                          value: val,
                                          child: Text(val),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null) provider.setFilter(val);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Notifications list
                    Expanded(
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.adminUid == null
                              ? const Center(child: Text('Admin not found'))
                              : StreamBuilder<QuerySnapshot>(
                                  stream: provider.notificationsStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return Center(child: Text('Error:  ${snapshot.error}'));
                                    }
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return const Center(child: Text('No notifications yet'));
                                    }
                                    final notifications = snapshot.data!.docs;
                                    final filteredNotifications = provider.filterAndSearch(notifications);
                                    return ListView.separated(
                                      itemCount: filteredNotifications.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final doc = filteredNotifications[index];
                                        final data = doc.data() as Map<String, dynamic>;
                                        return _buildNotificationCard(context, provider, data, doc.id);
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
        }
      },
    );
  }

  Widget _filterButton(BuildContext context, NotificationsProvider provider, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => provider.setFilter(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: appGreen,
            side: BorderSide(color: appGreen),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationsProvider provider, Map<String, dynamic> notif, String notificationId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;
    
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 16 : 20,
                  backgroundColor: const Color(0xFFe5faf3),
                  child: Icon(
                    provider.getNotificationIcon(notif['type'] ?? 'system'),
                    color: appGreen,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'] ?? 'Notification',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : isMediumScreen ? 14 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['body'] ?? '',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : isMediumScreen ? 12 : 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row with timestamp and actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.formatTime(notif['timestamp'] as Timestamp?),
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                      ),
                    ),
                    if (notif['read'] == false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: appGreen,
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (notif['read'] == false)
                      _actionButton(
                        context, 
                        'Mark as Read', 
                        Icons.check_circle, 
                        appGreen,
                        () => provider.markAsRead(notificationId),
                        isSmallScreen,
                      )
                    else
                      _actionButton(
                        context, 
                        'Mark as Unread', 
                        Icons.radio_button_unchecked, 
                        appGreen,
                        () => provider.markAsUnread(notificationId),
                        isSmallScreen,
                      ),
                    const SizedBox(width: 12),
                    _actionButton(
                      context, 
                      'Delete', 
                      Icons.delete_outline, 
                      appRed,
                      () => provider.deleteNotification(notificationId),
                      isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isSmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const AdminNotificationIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, _) {
        if (provider.adminUid == null) {
          return IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: onTap,
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: provider.notificationsStreamUnread,
          builder: (context, snapshot) {
            final hasUnread =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: onTap,
                ),
                if (hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
