import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../teacher_notifications/teacher_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import 'teacher_classes_web_provider.dart';
import '../teacher_schedule_class/teacher_schedule_class.dart';

// Simple and reliable URL launcher for Jitsi meetings
Future<void> _launchJitsiMeeting(String url) async {
  try {
    // Try to launch in external application first
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback: try to launch in new tab
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    }
  } catch (e) {
    // If all else fails, try to open in new tab
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (e) {
      throw Exception('Unable to open Jitsi meeting. Please try again or copy the URL manually.');
    }
  }
}

class TeacherClassesWebView extends StatelessWidget {
  const TeacherClassesWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherClassesWebProvider>(
      create: (_) => TeacherClassesWebProvider(),
      child: Consumer<TeacherClassesWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Classes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            StreamBuilder<QuerySnapshot>(
                              stream: NotificationService.getNotificationsStream(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount = snapshot.data!.docs.where((doc) => !(doc['read'] ?? false)).length;
                                }
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherNotificationScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: Row(
                          children: [
                            // Vertical Tab Bar
                            Container(
                              width: 250,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Color(0xFFE5EAF1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildTabItem(
                                    context,
                                    provider,
                                    'Upcoming',
                                    0,
                                    Icons.upcoming,
                                  ),
                                  _buildTabItem(
                                    context,
                                    provider,
                                    'Completed',
                                    1,
                                    Icons.check_circle,
                                  ),
                                  _buildTabItem(
                                    context,
                                    provider,
                                    'Missed',
                                    2,
                                    Icons.cancel,
                                  ),
                                ],
                              ),
                            ),
                            // Content Area
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 24,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: IndexedStack(
                                        index: provider.tabIndex,
                                        children: [
                                          _buildClassesList(provider.upcomingClasses, 'upcoming'),
                                          _buildClassesList(provider.completedClasses, 'completed'),
                                          _buildClassesList(provider.missedClasses, 'missed'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: appGreen,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ScheduleClassesScreen(),
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Schedule a Class',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildTabItem(
    BuildContext context,
    TeacherClassesWebProvider provider,
    String title,
    int index,
    IconData icon,
  ) {
    final isSelected = provider.tabIndex == index;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? appGreen.withOpacity(0.1) : Colors.transparent,
        border: Border(
          right: BorderSide(
            color: isSelected ? appGreen : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => provider.setTabIndex(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? appGreen : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? appGreen : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesList(List<DocumentSnapshot> classes, String type) {
    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48.0),
          child: Text(
            'No $type classes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final doc = classes[index];
        final data = doc.data() as Map<String, dynamic>;
        final studentName = data['studentName'] ?? 'Unknown Student';
        final date = data['date'] ?? '';
        final time = data['time'] ?? '';
        final jitsiRoom = data['jitsiRoom'] ?? '';
        final teacherJoined = data['teacherJoined'] ?? false;
        final description = data['description'] ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFe5faf3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (type == 'upcoming' && !teacherJoined)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton(
                    onPressed: jitsiRoom.isNotEmpty
                        ? () async {
                            try {
                              // Update teacher join status and set join time
                              await FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(doc.id)
                                  .update({
                                'teacherJoined': true,
                                'teacherJoinTime': FieldValue.serverTimestamp(),
                              });

                              // Launch Jitsi Meet
                              final url = 'https://meet.jit.si/$jitsiRoom';
                              
                              await _launchJitsiMeeting(url);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You have joined the class!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error joining class: $e')),
                                );
                              }
                            }
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: jitsiRoom.isNotEmpty ? Colors.green : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Join'),
                  ),
                ),
              if (type == 'upcoming' && teacherJoined)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Joined',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (type == 'completed')
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (type == 'missed')
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Missed',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
