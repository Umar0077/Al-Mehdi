import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../teacher_notifications/teacher_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import 'teacher_classes_web_provider.dart';
import '../teacher_schedule_class/teacher_schedule_class.dart';
import '../teacher_schedule_class/teacher_schedule_class_web.dart';

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
  final bool showScheduleClass;
  final void Function(bool) setShowScheduleClass;
  const TeacherClassesWebView({
    super.key,
    required this.showScheduleClass,
    required this.setShowScheduleClass,
  });

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
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    child:
                        showScheduleClass
                            ? const TeacherScheduleClassWeb()
                            : Column(
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
                                        stream:
                                            NotificationService.getNotificationsStream(),
                                        builder: (context, snapshot) {
                                          int unreadCount = 0;
                                          if (snapshot.hasData) {
                                            unreadCount =
                                                snapshot.data!.docs
                                                    .where(
                                                      (doc) =>
                                                          !(doc['read'] ??
                                                              false),
                                                    )
                                                    .length;
                                          }
                                          return Stack(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.notifications,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              TeacherNotificationScreen(),
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
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
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
                                  child:
                                      showScheduleClass
                                          ? const ScheduleClassesScreen()
                                          : Row(
                                            children: [
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
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 32),
                                                    _WebTab(
                                                      label: 'Upcoming',
                                                      selected:
                                                          provider.tabIndex ==
                                                          0,
                                                      onTap:
                                                          () => provider
                                                              .setTabIndex(0),
                                                    ),
                                                    _WebTab(
                                                      label: 'Completed',
                                                      selected:
                                                          provider.tabIndex ==
                                                          1,
                                                      onTap:
                                                          () => provider
                                                              .setTabIndex(1),
                                                    ),
                                                    _WebTab(
                                                      label: 'Missed',
                                                      selected:
                                                          provider.tabIndex ==
                                                          2,
                                                      onTap:
                                                          () => provider
                                                              .setTabIndex(2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 24,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: IndexedStack(
                                                          index:
                                                              provider.tabIndex,
                                                          children: [
                                                            _buildClassesList(
                                                              provider
                                                                  .upcomingClasses,
                                                              'upcoming',
                                                            ),
                                                            _buildClassesList(
                                                              provider
                                                                  .completedClasses,
                                                              'completed',
                                                            ),
                                                            _buildClassesList(
                                                              provider
                                                                  .missedClasses,
                                                              'missed',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(right: 32),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: appGreen,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        setShowScheduleClass(true);
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
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          );
        },
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

        // Parse class date and time
        DateTime? classDateTime;
        try {
          final dateParts = date.split('/');
          if (dateParts.length == 3) {
            final month = int.parse(dateParts[0]);
            final day = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            
            final timeReg = RegExp(r'(\d{1,2}):(\d{2})\s*([AP]M)', caseSensitive: false);
            final match = timeReg.firstMatch(time);
            if (match != null) {
              int hour = int.parse(match.group(1)!);
              final minute = int.parse(match.group(2)!);
              final period = match.group(3)!.toUpperCase();
              
              if (period == 'PM' && hour != 12) hour += 12;
              if (period == 'AM' && hour == 12) hour = 0;
              
              classDateTime = DateTime(year, month, day, hour, minute);
            }
          }
        } catch (_) {}

        final now = DateTime.now();
        
        // Check if class is within the joinable window (5 minutes before to 10 minutes after)
        final canJoin = classDateTime != null &&
            now.isAfter(classDateTime.subtract(const Duration(minutes: 5))) &&
            now.isBefore(classDateTime.add(const Duration(minutes: 10)));

        // Determine button text and color
        String buttonText;
        Color? buttonColor;
        bool isButtonEnabled = canJoin && jitsiRoom.isNotEmpty;

        if (type == 'upcoming') {
          if (canJoin) {
            buttonText = teacherJoined ? 'Rejoin' : 'Join';
            buttonColor = appGreen; // Green button during active window
          } else {
            buttonText = 'Join Class';
            buttonColor = (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700 
                : Colors.grey.shade300); // Grey button before active window
            isButtonEnabled = false;
          }
        } else if (type == 'completed') {
          buttonText = 'Completed';
          buttonColor = null;
          isButtonEnabled = false;
        } else if (type == 'missed') {
          buttonText = 'Missed';
          buttonColor = null;
          isButtonEnabled = false;
        } else {
          buttonText = 'Join';
          buttonColor = null;
          isButtonEnabled = false;
        }

        return Card(
          elevation: 2,
          shadowColor: Theme.of(context).shadowColor,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFe5faf3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.class_, color: appGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      Text(time, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(fontSize: 14)),
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
                      // Show button for all upcoming classes (active window or not)
                      if (type == 'upcoming')
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                                child: OutlinedButton(
                                  onPressed: isButtonEnabled
                                      ? () async {
                                          try {
                                            // Launch Jitsi immediately (non-blocking)
                                            final url = 'https://meet.jit.si/$jitsiRoom';
                                            unawaited(_launchJitsiMeeting(url));

                                            // Fire-and-forget: update join status
                                            unawaited(FirebaseFirestore.instance
                                                .collection('classes')
                                                .doc(doc.id)
                                                .update({
                                                  'teacherJoined': true,
                                                  'teacherJoinTime': FieldValue.serverTimestamp(),
                                                }).catchError((_) {}));

                                            // Fire-and-forget: notify the student
                                            final studentId = data['studentId'] ?? '';
                                            final teacherName = data['teacherName'] ?? '';
                                            final classId = doc.id;
                                            if (studentId.isNotEmpty) {
                                              unawaited(NotificationService
                                                      .sendJoinWaitingNotification(
                                                receiverId: studentId,
                                                senderName: teacherName,
                                                senderRole: 'teacher',
                                                classId: classId,
                                              ).catchError((_) {}));
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error joining class: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: canJoin ? Colors.white : (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black26),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(buttonText),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                      title: Center(child: const Text('Cancel Class', style: TextStyle(fontWeight: FontWeight.bold),)),
                                      content: const Text('Are you sure you want to cancel this class?'),
                                      actionsAlignment: MainAxisAlignment.center,
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('No', style: TextStyle(color: Colors.red),),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Yes'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(doc.id)
                                        .delete();

                                    // Notify the student
                                    final studentId = data['studentId'] ?? '';
                                    final teacherName = data['teacherName'] ?? '';
                                    final classDate = data['date'] ?? '';
                                    final classTime = data['time'] ?? '';
                                    if (studentId.isNotEmpty) {
                                      await NotificationService.sendNotificationWithRetry(
                                        userId: studentId,
                                        title: 'Class Cancelled',
                                        body: 'Your class scheduled on $classDate at $classTime has been cancelled by $teacherName.',
                                        type: 'class_cancelled',
                                        additionalData: {
                                          'teacherName': teacherName,
                                          'classDate': classDate,
                                          'classTime': classTime,
                                        },
                                      );
                                    }

                                    // Refresh provider to update UI
                                    final provider = Provider.of<TeacherClassesWebProvider>(context, listen: false);
                                    await provider.loadClasses();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Class cancelled.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      if (type == 'completed')
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: appGreen,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Add the _WebTab widget (copied from student_classes_web.dart)
class _WebTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _WebTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: selected ? 18 : 16,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 40 : 0,
              decoration: BoxDecoration(
                color: selected ? appGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
