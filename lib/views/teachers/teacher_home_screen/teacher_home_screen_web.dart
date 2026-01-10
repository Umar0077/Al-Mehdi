import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/colors.dart';
import '../../../components/students/student_sidebar.dart';
import '../../../providers/teachers/teacher_home_screen_web_provider.dart';
// import '../teacher_chat/teacher_chat_web.dart';
import '../../../services/notification_service.dart';
import '../teacher_attendance/teacher_attendance.dart';
import '../teacher_chat/teacher_chat.dart';
import '../teacher_classes_screen/teacher_classes.dart';
import '../teacher_notifications/teacher_notifications.dart';
import '../teacher_profile/teacher_profile.dart';
import '../teacher_settings/teacher_settings.dart';
// import 'package:intl/intl.dart';

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

class TeacherHomeScreenWeb extends StatelessWidget {
  const TeacherHomeScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<TeacherClassesScreenState> teacherClassesScreenKey =
        GlobalKey<TeacherClassesScreenState>();
    return ChangeNotifierProvider<TeacherHomeWebProvider>(
      create: (_) => TeacherHomeWebProvider(),
      child: Consumer<TeacherHomeWebProvider>(
        builder: (context, provider, _) {
          final List<Widget> screens = [
            TeacherHomeScreeenWeb(),
            TeacherClassesScreen(key: teacherClassesScreenKey),
            const TeacherAttendanceScreen(),
            const TeacherChatScreen(),
            const TeacherSettingsScreen(),
            const TeacherProfileScreen(),
          ];
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                StudentSidebar(
                  selectedIndex: provider.selectedIndex,
                  onItemSelected: (index) {
                    provider.setSelectedIndex(index);
                    if (index == 1 &&
                        teacherClassesScreenKey.currentState != null) {
                      teacherClassesScreenKey.currentState!
                          .resetToOriginalScreen();
                    }
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: provider.selectedIndex,
                    children: screens,
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

class TeacherHomeScreeenWeb extends StatelessWidget {
  const TeacherHomeScreeenWeb({super.key});

  String _parseTimeTo24Hour(String? time) {
    if (time == null || time.isEmpty) {
      return '00:00:00';
    }
    final timeReg = RegExp(
      r'(\d{1,2}):(\d{2})\s*([AP]M)',
      caseSensitive: false,
    );
    final match = timeReg.firstMatch(time);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
    }
    return '00:00:00';
  }

  DateTime? parseClassDateTime(String? date, String? time) {
    try {
      if (date == null || time == null || date.isEmpty || time.isEmpty) {
        return null;
      }
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final timeReg = RegExp(
          r'(\d{1,2}):(\d{2})\s*([AP]M)',
          caseSensitive: false,
        );
        final match = timeReg.firstMatch(time);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          final period = match.group(3)!.toUpperCase();
          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherHomeWebProvider>(context);
    final fullName = provider.fullName;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sidebar(selectedIndex: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      Text(
                        fullName != null
                            ? '👋 Welcome, $fullName!'
                            : '👋 Welcome, Teacher!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Notification Icon with badge
                      StreamBuilder<QuerySnapshot>(
                        stream: NotificationService.getNotificationsStream(),
                        builder: (context, snapshot) {
                          int unreadCount = 0;
                          if (snapshot.hasData) {
                            unreadCount =
                                snapshot.data!.docs
                                    .where((doc) => !(doc['read'] ?? false))
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
                                          (_) => TeacherNotificationScreen(),
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
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            provider.profilePictureUrl != null
                                ? NetworkImage(provider.profilePictureUrl!)
                                : null,
                        child:
                            provider.profilePictureUrl == null
                                ? const Icon(Icons.person, size: 20)
                                : null,
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Do you really want to logout?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
                              }
                            } catch (_) {}
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Info and Attendance
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe5faf3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  fullName != null
                                      ? "Glad to have you back, $fullName! Let's make today count."
                                      : "Glad to have you back, Teacher! Let's make today count.",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Attendance Summary',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                // Switch to Attendance tab (index 2) using the provider
                                                Provider.of<
                                                  TeacherHomeWebProvider
                                                >(
                                                  context,
                                                  listen: false,
                                                ).setSelectedIndex(2);
                                              },
                                              child: const Text(
                                                "Mark",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<QuerySnapshot>(
                                      future:
                                          FirebaseFirestore.instance
                                              .collection('classes')
                                              .where(
                                                'teacherId',
                                                isEqualTo:
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid,
                                              )
                                              .where(
                                                'status',
                                                isEqualTo: 'completed',
                                              )
                                              .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text('Loading...');
                                        }
                                        if (!snapshot.hasData) {
                                          return const Text(
                                            '0 / 0 Classes Marked',
                                          );
                                        }
                                        final allClasses = snapshot.data!.docs;
                                        final total = allClasses.length;
                                        final marked =
                                            allClasses.where((doc) {
                                              final data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              return data.containsKey(
                                                'attendanceStatus',
                                              );
                                            }).length;
                                        return Text(
                                          '$marked / $total Classes Marked',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Keep up the great work! 🎉',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right column: Classes and Conversations
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active Classes Section
                                FutureBuilder<QuerySnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('classes')
                                          .where(
                                            'teacherId',
                                            isEqualTo:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                          )
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    final now = DateTime.now();
                                    final activeClasses =
                                        snapshot.data!.docs.where((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final date = data['date'] ?? '';
                                          final time = data['time'] ?? '';
                                          final classDateTime =
                                              parseClassDateTime(date, time);

                                          // Only show classes that are currently in the active window
                                          return classDateTime != null &&
                                              now.isAfter(
                                                classDateTime.subtract(
                                                  const Duration(minutes: 5),
                                                ),
                                              ) &&
                                              now.isBefore(
                                                classDateTime.add(
                                                  const Duration(minutes: 10),
                                                ),
                                              );
                                        }).toList();

                                    if (activeClasses.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Active Classes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Column(
                                          children:
                                              activeClasses.map((doc) {
                                                final data =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                final classDate =
                                                    data['date'] ?? '';
                                                final classTime =
                                                    data['time'] ?? '';
                                                final jitsiRoom =
                                                    data['jitsiRoom'] ?? '';
                                                final assignedStudentId =
                                                    data['studentId'] ?? '';
                                                final teacherJoined =
                                                    data['teacherJoined'] ??
                                                    false;

                                                return FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                            'students',
                                                          )
                                                          .doc(
                                                            assignedStudentId,
                                                          )
                                                          .get(),
                                                  builder: (
                                                    context,
                                                    studentSnapshot,
                                                  ) {
                                                    String studentName =
                                                        'Student';
                                                    if (studentSnapshot
                                                            .hasData &&
                                                        studentSnapshot
                                                            .data!
                                                            .exists) {
                                                      studentName =
                                                          studentSnapshot
                                                              .data!['fullName'] ??
                                                          'Student';
                                                    }
                                                    return _WebClassCard(
                                                      title: studentName,
                                                      time: classTime,
                                                      teacher: classDate,
                                                      text:
                                                          teacherJoined
                                                              ? 'Rejoin'
                                                              : 'Join Class',
                                                      roomName: jitsiRoom,
                                                      canJoin:
                                                          true, // Active classes always have green buttons
                                                      onJoin:
                                                          jitsiRoom.isNotEmpty
                                                              ? () async {
                                                                try {
                                                                  final url =
                                                                      'https://meet.jit.si/$jitsiRoom';

                                                                  await _launchJitsiMeeting(
                                                                    url,
                                                                  );

                                                                  // Mark as joined and track join time
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                        'classes',
                                                                      )
                                                                      .doc(
                                                                        doc.id,
                                                                      )
                                                                      .update({
                                                                        'teacherJoined':
                                                                            true,
                                                                        'teacherJoinTime':
                                                                            FieldValue.serverTimestamp(),
                                                                      });

                                                                  // Send notification to student
                                                                  final studentId =
                                                                      data['studentId'] ??
                                                                      '';
                                                                  final teacherName =
                                                                      data['teacherName'] ??
                                                                      '';
                                                                  // studentName not used here
                                                                  final classId =
                                                                      doc.id;
                                                                  if (studentId
                                                                      .isNotEmpty) {
                                                                    await NotificationService.sendJoinWaitingNotification(
                                                                      receiverId:
                                                                          studentId,
                                                                      senderName:
                                                                          teacherName,
                                                                      senderRole:
                                                                          'teacher',
                                                                      classId:
                                                                          classId,
                                                                    );
                                                                  }

                                                                  if (context
                                                                      .mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      const SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'You have joined the class!',
                                                                            ),
                                                                      ),
                                                                    );
                                                                  }
                                                                } catch (e) {
                                                                  if (context
                                                                      .mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'Error joining class: $e',
                                                                            ),
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              }
                                                              : null,
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  },
                                ),
                                const Text(
                                  'Upcoming Scheduled Classes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Fetch upcoming classes from Firestore
                                FutureBuilder<QuerySnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('classes')
                                          .where(
                                            'teacherId',
                                            isEqualTo:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                          )
                                          .where(
                                            'status',
                                            isEqualTo: 'upcoming',
                                          )
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Text('No upcoming classes');
                                    }
                                    final now = DateTime.now();
                                    final classes =
                                        snapshot.data!.docs.where((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final date = data['date'] ?? '';
                                          final time = data['time'] ?? '';
                                          DateTime? classDateTime;
                                          try {
                                            classDateTime = parseClassDateTime(
                                              date,
                                              time,
                                            );
                                          } catch (_) {
                                            classDateTime = null;
                                          }
                                          // Show all classes that haven't ended their join window yet (10 minutes after)
                                          return classDateTime != null &&
                                              now.isBefore(
                                                classDateTime.add(
                                                  const Duration(minutes: 10),
                                                ),
                                              );
                                        }).toList();

                                    // Sort by classDateTime ascending
                                    classes.sort((a, b) {
                                      DateTime getDateTime(
                                        QueryDocumentSnapshot doc,
                                      ) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final date = data['date'] ?? '';
                                        final time = data['time'] ?? '';
                                        final parts = date.split('/');
                                        if (parts.length == 3) {
                                          final month = int.parse(parts[0]);
                                          final day = int.parse(parts[1]);
                                          final year = int.parse(parts[2]);
                                          final time24 = _parseTimeTo24Hour(
                                            time,
                                          );
                                          final timeParts = time24.split(':');
                                          final hour = int.parse(timeParts[0]);
                                          final minute = int.parse(
                                            timeParts[1],
                                          );
                                          return DateTime(
                                            year,
                                            month,
                                            day,
                                            hour,
                                            minute,
                                          );
                                        }
                                        return DateTime(1970);
                                      }

                                      return getDateTime(
                                        a,
                                      ).compareTo(getDateTime(b));
                                    });

                                    if (classes.isEmpty) {
                                      return const Text('No upcoming classes');
                                    }
                                    return Column(
                                      children:
                                          classes.map((doc) {
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final classDate =
                                                data['date'] ?? '';
                                            final classTime =
                                                data['time'] ?? '';
                                            final jitsiRoom =
                                                data['jitsiRoom'] ?? '';
                                            final assignedStudentId =
                                                data['studentId'] ?? '';
                                            final teacherJoined =
                                                data['teacherJoined'] ?? false;

                                            // Parse classDateTime using the same logic as filtering
                                            final classDateTime =
                                                parseClassDateTime(
                                                  classDate,
                                                  classTime,
                                                );
                                            // --- MAIN CLASS LIST ---
                                            final canJoin =
                                                classDateTime != null &&
                                                DateTime.now().isAfter(
                                                  classDateTime.subtract(
                                                    const Duration(minutes: 5),
                                                  ),
                                                ) &&
                                                DateTime.now().isBefore(
                                                  classDateTime.add(
                                                    const Duration(minutes: 10),
                                                  ),
                                                );
                                            final isCompleted =
                                                classDateTime != null &&
                                                DateTime.now().isAfter(
                                                  classDateTime.add(
                                                    const Duration(minutes: 10),
                                                  ),
                                                );

                                            return FutureBuilder<
                                              DocumentSnapshot
                                            >(
                                              future:
                                                  FirebaseFirestore.instance
                                                      .collection('students')
                                                      .doc(assignedStudentId)
                                                      .get(),
                                              builder: (
                                                context,
                                                studentSnapshot,
                                              ) {
                                                String studentName = 'Student';
                                                if (studentSnapshot.hasData &&
                                                    studentSnapshot
                                                        .data!
                                                        .exists) {
                                                  studentName =
                                                      studentSnapshot
                                                          .data!['fullName'] ??
                                                      'Student';
                                                }
                                                return _WebClassCard(
                                                  title: studentName,
                                                  time: classTime,
                                                  teacher: classDate,
                                                  text:
                                                      isCompleted
                                                          ? (teacherJoined
                                                              ? 'Completed'
                                                              : 'Missed')
                                                          : (teacherJoined
                                                              ? 'Rejoin'
                                                              : 'Join Class'),
                                                  roomName: jitsiRoom,
                                                  canJoin:
                                                      canJoin, // Pass the canJoin status for button color
                                                  onJoin:
                                                      canJoin &&
                                                              jitsiRoom
                                                                  .isNotEmpty
                                                          ? () async {
                                                            final url =
                                                                'https://meet.jit.si/$jitsiRoom';
                                                            await _launchJitsiMeeting(
                                                              url,
                                                            );
                                                            // Mark as joined and track join time
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'classes',
                                                                )
                                                                .doc(doc.id)
                                                                .update({
                                                                  'teacherJoined':
                                                                      true,
                                                                  'teacherJoinTime':
                                                                      FieldValue.serverTimestamp(),
                                                                });
                                                          }
                                                          : null,
                                                );
                                              },
                                            );
                                          }).toList(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Recent Conversations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Show recent conversations with students
                                FutureBuilder<QuerySnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('students')
                                          .where(
                                            'assignedTeacherId',
                                            isEqualTo:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                          )
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Text(
                                        'No conversations found',
                                      );
                                    }
                                    final students = snapshot.data!.docs;
                                    return Column(
                                      children:
                                          students.map((doc) {
                                            final studentId = doc.id;
                                            final studentName =
                                                doc['fullName'] ?? 'Student';
                                            final teacherId =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid;
                                            final chatRoomIdList = [
                                              teacherId,
                                              studentId,
                                            ]..sort();
                                            final chatRoomDocId =
                                                '${chatRoomIdList[0]}_${chatRoomIdList[1]}';

                                            return FutureBuilder<
                                              DocumentSnapshot
                                            >(
                                              future:
                                                  FirebaseFirestore.instance
                                                      .collection('chatRooms')
                                                      .doc(chatRoomDocId)
                                                      .get(),
                                              builder: (
                                                context,
                                                chatRoomSnapshot,
                                              ) {
                                                String lastMessage =
                                                    'No messages yet';
                                                String timeText = '';
                                                if (chatRoomSnapshot.hasData &&
                                                    chatRoomSnapshot
                                                        .data!
                                                        .exists) {
                                                  final data =
                                                      chatRoomSnapshot.data!
                                                              .data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  lastMessage =
                                                      data['lastMessage'] ??
                                                      'No messages yet';
                                                  final lastMessageTime =
                                                      data['lastMessageTime'];
                                                  if (lastMessageTime != null) {
                                                    final dt =
                                                        (lastMessageTime
                                                                as Timestamp)
                                                            .toDate();
                                                    final now = DateTime.now();
                                                    final diff = now.difference(
                                                      dt,
                                                    );
                                                    if (diff.inMinutes < 1) {
                                                      timeText = 'Now';
                                                    } else if (diff.inMinutes <
                                                        60) {
                                                      timeText =
                                                          '${diff.inMinutes}m ago';
                                                    } else if (diff.inHours <
                                                        24) {
                                                      timeText =
                                                          '${diff.inHours}h ago';
                                                    } else {
                                                      timeText =
                                                          '${dt.day}/${dt.month}/${dt.year}';
                                                    }
                                                  }
                                                }
                                                return Column(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        // Switch to Chat tab (index 3) using the provider
                                                        Provider.of<
                                                          TeacherHomeWebProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        ).setSelectedIndex(3);
                                                      },
                                                      child:
                                                          _WebConversationCard(
                                                            name: studentName,
                                                            message:
                                                                lastMessage,
                                                            time: timeText,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                );
                                              },
                                            );
                                          }).toList(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
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
          ),
        ],
      ),
    );
  }
}

class _WebClassCard extends StatelessWidget {
  final String title;
  final String time;
  final String teacher;
  final String text;
  final String roomName;
  final VoidCallback? onJoin;
  final bool canJoin; // New parameter to control button color

  const _WebClassCard({
    required this.title,
    required this.time,
    required this.teacher,
    required this.text,
    required this.roomName,
    this.onJoin,
    this.canJoin = false, // Default to false for grey button
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Icon(Iconsax.teacher, color: appGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Widget joinButton = OutlinedButton(
                    onPressed: onJoin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.transparent),
                      backgroundColor:
                          canJoin
                              ? appGreen
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors
                                      .grey
                                      .shade700 // Dark mode border color
                                  : Colors.grey.shade300),
                      foregroundColor:
                          canJoin
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors
                                      .white70 // Lighter text in dark mode when disabled
                                  : Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(text),
                  );

                  if (constraints.maxWidth > 400) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(time, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                teacher,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 80,
                            maxWidth: 120,
                          ),
                          child: joinButton,
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(time, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(teacher, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: joinButton),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebConversationCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;

  const _WebConversationCard({
    required this.name,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFe5faf3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Iconsax.user, color: appGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
