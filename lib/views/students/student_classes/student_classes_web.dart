import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/classes/student_classes_web_provider.dart';
import '../../../services/notification_service.dart';
import '../student_notifications/student_notifications.dart';

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
      throw Exception(
        'Unable to open Jitsi meeting. Please try again or copy the URL manually.',
      );
    }
  }
}

class StudentClassesWebView extends StatelessWidget {
  const StudentClassesWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentClassesWebProvider>(
      create: (_) => StudentClassesWebProvider(),
      child: Consumer<StudentClassesWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                // Sidebar removed; handled by parent layout
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
                              stream:
                                  NotificationService.getNotificationsStream(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount =
                                      snapshot.data!.docs
                                          .where(
                                            (doc) => !(doc['read'] ?? false),
                                          )
                                          .length;
                                }
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    StudentNotificationScreen(),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 32),
                                  _WebTab(
                                    label: 'Upcoming',
                                    selected: provider.tabIndex == 0,
                                    onTap: () => provider.setTabIndex(0),
                                  ),
                                  _WebTab(
                                    label: 'Completed',
                                    selected: provider.tabIndex == 1,
                                    onTap: () => provider.setTabIndex(1),
                                  ),
                                  _WebTab(
                                    label: 'Missed',
                                    selected: provider.tabIndex == 2,
                                    onTap: () => provider.setTabIndex(2),
                                  ),
                                ],
                              ),
                            ),
                            // Tab Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 24,
                                ),
                                child: IndexedStack(
                                  index: provider.tabIndex,
                                  children: [
                                    _UpcomingStudentClassesTab(),
                                    _CompletedStudentClassesTab(),
                                    _MissedStudentClassesTab(),
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
}

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

// --- UPCOMING TAB ---
class _UpcomingStudentClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('classes')
              .where('studentId', isEqualTo: userId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: Center(
                child: Text(
                  'No upcoming classes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final classes =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              DateTime? classDateTime;
              if (data['scheduledAt'] != null) {
                classDateTime =
                    (data['scheduledAt'] as Timestamp).toDate().toLocal();
              } else {
                final date = data['date'] ?? '';
                final time = data['time'] ?? '';
                classDateTime = _parseClassDateTime(date, time);
              }
              final joinWindowEnd = classDateTime?.add(
                const Duration(minutes: 10),
              );
              // Show all classes that haven't ended their join window yet
              return classDateTime != null && now.isBefore(joinWindowEnd!);
            }).toList();

        classes.sort((a, b) {
          DateTime getDateTime(QueryDocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['scheduledAt'] != null) {
              return (data['scheduledAt'] as Timestamp).toDate().toLocal();
            }
            final date = data['date'] ?? '';
            final time = data['time'] ?? '';
            return _parseClassDateTime(date, time) ?? DateTime(1970);
          }

          return getDateTime(a).compareTo(getDateTime(b));
        });

        if (classes.isEmpty) {
          return Center(
            child: Text(
              'No upcoming classes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return ListView(
          children:
              classes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final teacherName = data['teacherName'] ?? 'Teacher';
                final jitsiRoom = data['jitsiRoom'] ?? '';
                final studentJoined = data['studentJoined'] ?? false;

                DateTime? classDateTime;
                if (data['scheduledAt'] != null) {
                  classDateTime =
                      (data['scheduledAt'] as Timestamp).toDate().toLocal();
                } else {
                  final classDate = data['date'] ?? '';
                  final classTime = data['time'] ?? '';
                  classDateTime = _parseClassDateTime(classDate, classTime);
                }

                final now = DateTime.now();
                final joinWindowStart = classDateTime?.subtract(
                  const Duration(minutes: 5),
                );
                final joinWindowEnd = classDateTime?.add(
                  const Duration(minutes: 10),
                );

                final isInJoinWindow =
                    classDateTime != null &&
                    joinWindowStart != null &&
                    joinWindowEnd != null &&
                    now.isAfter(joinWindowStart) &&
                    now.isBefore(joinWindowEnd);

                final canJoin = isInJoinWindow;
                final isCompleted =
                    classDateTime != null &&
                    now.isAfter(classDateTime.add(const Duration(minutes: 10)));
                final isMissed = !studentJoined && isCompleted;

                final displayTime =
                    classDateTime != null
                        ? TimeOfDay.fromDateTime(classDateTime).format(context)
                        : (data['time'] ?? '');
                final displayDate =
                    classDateTime != null
                        ? DateFormat('yyyy-MM-dd').format(classDateTime)
                        : (data['date'] ?? '');

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
                                teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayTime,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayDate,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        isMissed
                            ? const Text(
                              'Missed',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : isCompleted
                            ? (studentJoined
                                ? const Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : const Text(
                                  'Missed',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ))
                            : OutlinedButton(
                              onPressed:
                                  canJoin && jitsiRoom.isNotEmpty
                                      ? () async {
                                        try {
                                          final url =
                                              'https://meet.jit.si/$jitsiRoom';

                                          await _launchJitsiMeeting(url);

                                          // Update Firestore after successful launch
                                          await FirebaseFirestore.instance
                                              .collection('classes')
                                              .doc(doc.id)
                                              .update({
                                                'studentJoined': true,
                                                'studentJoinTime':
                                                    FieldValue.serverTimestamp(),
                                              });

                                          // Send notification to teacher
                                          final teacherId =
                                              data['teacherId'] ?? '';
                                          final teacherName =
                                              data['teacherName'] ?? '';
                                          final studentName =
                                              data['studentName'] ?? '';
                                          final classId = doc.id;
                                          if (teacherId.isNotEmpty) {
                                            await NotificationService.sendJoinWaitingNotification(
                                              receiverId: teacherId,
                                              senderName: studentName,
                                              senderRole: 'student',
                                              classId: classId,
                                            );
                                          }

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'You have joined the class!',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error joining class: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                      : null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    canJoin
                                        ? appGreen
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors
                                                .grey
                                                .shade700 // Dark mode border color
                                            : Colors
                                                .grey
                                                .shade300), // Light mode border color
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                studentJoined && isInJoinWindow
                                    ? 'Rejoin'
                                    : 'Join',
                                style: TextStyle(
                                  color:
                                      canJoin
                                          ? Colors
                                              .white // White text when can join
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .white70 // Lighter text in dark mode when disabled
                                              : Colors
                                                  .black26), // Dark text when in light mode
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

// --- COMPLETED TAB ---
class _CompletedStudentClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('classes')
              .where('studentId', isEqualTo: userId)
              .where('studentJoined', isEqualTo: true)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: Center(
                child: Text(
                  'No completed classes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final completedClasses =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentJoined = data['studentJoined'] ?? false;
              DateTime? classDateTime;
              if (data['scheduledAt'] != null) {
                classDateTime =
                    (data['scheduledAt'] as Timestamp).toDate().toLocal();
              } else {
                final date = data['date'] ?? '';
                final time = data['time'] ?? '';
                classDateTime = _parseClassDateTime(date, time);
              }
              // Completed if student joined and class ended (10 minutes after start)
              return studentJoined &&
                  classDateTime != null &&
                  now.isAfter(classDateTime.add(const Duration(minutes: 10)));
            }).toList();

        if (completedClasses.isEmpty) {
          return Center(
            child: Text(
              'No completed classes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return ListView(
          children:
              completedClasses.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final teacherName = data['teacherName'] ?? '';
                DateTime? classDateTime;
                if (data['scheduledAt'] != null) {
                  classDateTime =
                      (data['scheduledAt'] as Timestamp).toDate().toLocal();
                } else {
                  final classDate = data['date'] ?? '';
                  final classTime = data['time'] ?? '';
                  classDateTime = _parseClassDateTime(classDate, classTime);
                }
                final displayTime =
                    classDateTime != null
                        ? TimeOfDay.fromDateTime(classDateTime).format(context)
                        : (data['time'] ?? '');
                final displayDate =
                    classDateTime != null
                        ? DateFormat('yyyy-MM-dd').format(classDateTime)
                        : (data['date'] ?? '');
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
                                teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayTime,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayDate,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

// --- MISSED TAB ---
class _MissedStudentClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('classes')
              .where('studentId', isEqualTo: userId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: Center(
                child: Text(
                  'No missed classes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final missedClasses =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentJoined = data['studentJoined'] ?? false;
              DateTime? classDateTime;
              if (data['scheduledAt'] != null) {
                classDateTime =
                    (data['scheduledAt'] as Timestamp).toDate().toLocal();
              } else {
                final date = data['date'] ?? '';
                final time = data['time'] ?? '';
                classDateTime = _parseClassDateTime(date, time);
              }
              final missedThreshold = classDateTime?.add(
                const Duration(minutes: 10),
              );
              return !studentJoined &&
                  missedThreshold != null &&
                  missedThreshold.isBefore(now);
            }).toList();

        if (missedClasses.isEmpty) {
          return Center(
            child: Text(
              'No missed classes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return ListView(
          children:
              missedClasses.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final teacherName = data['teacherName'] ?? '';
                DateTime? classDateTime;
                if (data['scheduledAt'] != null) {
                  classDateTime =
                      (data['scheduledAt'] as Timestamp).toDate().toLocal();
                } else {
                  final classDate = data['date'] ?? '';
                  final classTime = data['time'] ?? '';
                  classDateTime = _parseClassDateTime(classDate, classTime);
                }
                final displayTime =
                    classDateTime != null
                        ? TimeOfDay.fromDateTime(classDateTime).format(context)
                        : (data['time'] ?? '');
                final displayDate =
                    classDateTime != null
                        ? DateFormat('yyyy-MM-dd').format(classDateTime)
                        : (data['date'] ?? '');
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
                                teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayTime,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayDate,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Missed',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

// Helper function for time parsing
DateTime? _parseClassDateTime(String date, String time) {
  try {
    final parts = date.split('/');
    if (parts.length == 3) {
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final timeRegExp = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false);
      final match = timeRegExp.firstMatch(time);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String period = match.group(3)!.toUpperCase();
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        return DateTime(year, month, day, hour, minute);
      }
    }
  } catch (_) {}
  return null;
}
