import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  String filterValue = 'All';
  final TextEditingController searchController = TextEditingController();
  String? adminUid;
  bool isLoading = true;

  void initialize() async {
    await _getAdminUid();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _getAdminUid() async {
    final adminQuery = await FirebaseFirestore.instance.collection('admin').limit(1).get();
    if (adminQuery.docs.isNotEmpty) {
      adminUid = adminQuery.docs.first.id;
    }
  }

  void setFilter(String value) {
    filterValue = value;
    notifyListeners();
  }

  void setSearchTerm(String value) {
    notifyListeners();
  }

  Stream<QuerySnapshot>? get notificationsStream =>
    adminUid == null ? null : FirebaseFirestore.instance.collection('users').doc(adminUid).collection('notifications').orderBy('timestamp', descending: true).snapshots();

  Stream<QuerySnapshot>? get notificationsStreamUnread =>
    adminUid == null ? null : FirebaseFirestore.instance.collection('users').doc(adminUid).collection('notifications').where('read', isEqualTo: false).snapshots();

  List<QueryDocumentSnapshot> filterAndSearch(List<QueryDocumentSnapshot> notifications) {
    var filtered = notifications;
    if (filterValue == 'Read') {
      filtered = notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == true).toList();
    } else if (filterValue == 'Unread') {
      filtered = notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == false).toList();
    }
    if (searchController.text.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['title']?.toString().toLowerCase().contains(searchController.text.toLowerCase()) ?? false) ||
               (data['body']?.toString().toLowerCase().contains(searchController.text.toLowerCase()) ?? false);
      }).toList();
    }
    return filtered;
  }

  int countUnread(List<QueryDocumentSnapshot> notifications) =>
    notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == false).length;
  int countRead(List<QueryDocumentSnapshot> notifications) =>
    notifications.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == true).length;

  String formatTime(Timestamp? timestamp) {
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

  IconData getNotificationIcon(String type) {
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

  Future<void> markAsRead(String notificationId) async {
    if (adminUid == null) return;
    await NotificationService.markNotificationAsRead(notificationId, userId: adminUid);
    notifyListeners();
  }

  Future<void> markAsUnread(String notificationId) async {
    if (adminUid == null) return;
    await NotificationService.markNotificationAsUnread(notificationId, userId: adminUid);
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (adminUid == null) return;
    await NotificationService.deleteNotification(notificationId, userId: adminUid);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (adminUid == null) return;
    final snapshot = await NotificationService.getNotificationsStream().first;
    for (var doc in snapshot.docs) {
      if ((doc.data() as Map<String, dynamic>)['read'] == false) {
        await NotificationService.markNotificationAsRead(doc.id, userId: adminUid);
      }
    }
    notifyListeners();
  }

  Future<void> deleteAll() async {
    if (adminUid == null) return;
    final snapshot = await NotificationService.getNotificationsStream().first;
    for (var doc in snapshot.docs) {
      await NotificationService.deleteNotification(doc.id, userId: adminUid);
    }
    notifyListeners();
  }
}
