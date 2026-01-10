import 'package:al_mehdi_online_school/views/teachers/teacher_classes_screen/teacher_classes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/teachers/home/teacher_home_view_mobile_provider.dart';
import '../../../services/notification_service.dart';
import '../teacher_attendance/teacher_attendance.dart';
import '../teacher_chat/teacher_chat.dart';
import '../teacher_notifications/teacher_notifications.dart';
import '../teacher_profile/teacher_profile.dart';
import '../teacher_schedule_class/teacher_schedule_class.dart';
import '../teacher_settings/teacher_settings.dart';

class TeacherHomeScreenMobile extends StatelessWidget {
  const TeacherHomeScreenMobile({super.key});

  void joinJitsiMeeting(
    BuildContext context,
    String room,
    String? fullName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not found.')));
      return;
    }
    final options = JitsiMeetConferenceOptions(
      room: room,
      userInfo: JitsiMeetUserInfo(displayName: fullName ?? 'Teacher'),
      featureFlags: {
        "welcomepage.enabled": false,
        "startWithAudioMuted": false,
        "startWithVideoMuted": false,
      },
    );
    await JitsiMeet().join(options);
  }

  Widget _buildBody(BuildContext context, int selectedIndex, String? fullName) {
    switch (selectedIndex) {
      case 0:
        return _HomeTab(
          fullName: fullName,
          joinJitsiMeeting: (room) => joinJitsiMeeting(context, room, fullName),
        );
      case 1:
        return const TeacherClassesScreen();
      case 2:
        return const TeacherChatScreen();
      case 3:
        return const TeacherSettingsScreen();
      case 4:
        return const TeacherProfileScreen();
      default:
        return _HomeTab(
          fullName: fullName,
          joinJitsiMeeting: (room) => joinJitsiMeeting(context, room, fullName),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherHomeMobileProvider(),
      child: Consumer<TeacherHomeMobileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _buildBody(
              context,
              provider.selectedIndex,
              provider.fullName,
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: provider.selectedIndex,
              onTap: provider.setSelectedIndex,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: 'Classes',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String? fullName;
  final void Function(String) joinJitsiMeeting;

  const _HomeTab({required this.fullName, required this.joinJitsiMeeting});

  DateTime? parseClassDateTime(String? date, String? time) {
    if (date == null || time == null) return null;

    try {
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fullName != null
                            ? '👋 Welcome, $fullName!'
                            : '👋 Welcome, Teacher!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                                  builder: (_) => TeacherNotificationScreen(),
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
              const SizedBox(height: 24),
              // Info Card
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
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              const SizedBox(height: 24),
              // Attendance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const TeacherAttendanceScreen(),
                              ),
                            );
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
                    const SizedBox(height: 8),
                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('classes')
                              .where(
                                'teacherId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              .where('status', isEqualTo: 'completed')
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading...');
                        }
                        if (!snapshot.hasData) {
                          return const Text('0 / 0 Classes Marked');
                        }
                        final allClasses = snapshot.data!.docs;
                        final total = allClasses.length;
                        final marked =
                            allClasses.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data.containsKey('attendanceStatus');
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
              const SizedBox(height: 24),
              // Active Classes Section
              FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('classes')
                        .where(
                          'teacherId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                        )
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final now = DateTime.now();
                  final activeClasses =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final date = data['date'] as String?;
                        final time = data['time'] as String?;

                        if (date == null || time == null) return false;

                        final classDateTime = parseClassDateTime(date, time);
                        // Only show classes that are currently in the active window
                        return classDateTime != null &&
                            now.isAfter(
                              classDateTime.subtract(
                                const Duration(minutes: 5),
                              ),
                            ) &&
                            now.isBefore(
                              classDateTime.add(const Duration(minutes: 10)),
                            );
                      }).toList();

                  if (activeClasses.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Classes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activeClasses.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final classDate = data['date'] ?? '';
                        final classTime = data['time'] ?? '';
                        final jitsiRoom = data['jitsiRoom'] ?? '';
                        final teacherJoined = data['teacherJoined'] ?? false;

                        return Card(
                          elevation: 2,
                          color: Theme.of(context).cardColor,
                          shadowColor: Theme.of(context).shadowColor,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFe5faf3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(8),
                              child: Icon(Iconsax.teacher, color: appGreen),
                            ),
                            title: FutureBuilder<DocumentSnapshot>(
                              future:
                                  (data['studentId'] != null)
                                      ? FirebaseFirestore.instance
                                          .collection('students')
                                          .doc(data['studentId'])
                                          .get()
                                      : null,
                              builder: (context, studentSnapshot) {
                                String studentName = 'Student';
                                if (studentSnapshot.hasData &&
                                    studentSnapshot.data!.exists) {
                                  final studentData =
                                      studentSnapshot.data!.data()
                                          as Map<String, dynamic>?;
                                  studentName =
                                      studentData?['fullName'] ?? 'Student';
                                }
                                return Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                            subtitle: Builder(
                              builder: (context) {
                                DateTime? localDateTime;
                                if (data['scheduledAt'] != null) {
                                  localDateTime =
                                      (data['scheduledAt'] as Timestamp)
                                          .toDate()
                                          .toLocal();
                                } else {
                                  localDateTime = parseClassDateTime(
                                    classDate,
                                    classTime,
                                  );
                                }
                                final displayTime =
                                    localDateTime != null
                                        ? TimeOfDay.fromDateTime(
                                          localDateTime,
                                        ).format(context)
                                        : classTime;
                                final displayDate =
                                    localDateTime != null
                                        ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(localDateTime)
                                        : classDate;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayTime),
                                    Text(displayDate),
                                  ],
                                );
                              },
                            ),
                            trailing: OutlinedButton(
                              onPressed:
                                  jitsiRoom.isNotEmpty
                                      ? () async {
                                        await FirebaseFirestore.instance
                                            .collection('classes')
                                            .doc(doc.id)
                                            .update({
                                              'teacherJoined': true,
                                              'teacherJoinTime':
                                                  FieldValue.serverTimestamp(),
                                            });
                                        // Send notification to student
                                        final studentId =
                                            data['studentId'] ?? '';
                                        final teacherName =
                                            data['teacherName'] ?? '';
                                        final studentName =
                                            data['studentName'] ?? '';
                                        final classId = doc.id;
                                        if (studentId.isNotEmpty) {
                                          await NotificationService.sendJoinWaitingNotification(
                                            receiverId: studentId,
                                            senderName: teacherName,
                                            senderRole: 'teacher',
                                            classId: classId,
                                          );
                                        }
                                        joinJitsiMeeting(jitsiRoom);
                                      }
                                      : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.transparent),
                                backgroundColor:
                                    jitsiRoom.isNotEmpty
                                        ? appGreen
                                        : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(teacherJoined ? 'Rejoin' : 'Join'),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              // Upcoming Scheduled Classes
              const Text(
                'Upcoming Scheduled Classes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              // Upcoming Classes List
              FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('classes')
                        .where(
                          'teacherId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                        )
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text('No upcoming classes'),
                    );
                  }
                  final now = DateTime.now();
                  final classes =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final date = data['date'] as String?;
                        final time = data['time'] as String?;

                        // Skip if date or time is null
                        if (date == null || time == null) return false;

                        final classDateTime = parseClassDateTime(date, time);
                        // Show all classes that haven't ended their join window yet (10 minutes after)
                        return classDateTime != null &&
                            now.isBefore(
                              classDateTime.add(const Duration(minutes: 10)),
                            );
                      }).toList();

                  // Sort by classDateTime ascending
                  classes.sort((a, b) {
                    DateTime getDateTime(QueryDocumentSnapshot doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = data['date'] as String?;
                      final time = data['time'] as String?;

                      if (date == null || time == null) return DateTime(1970);

                      final dt = parseClassDateTime(date, time);
                      return dt ?? DateTime(1970);
                    }

                    return getDateTime(a).compareTo(getDateTime(b));
                  });

                  if (classes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text('No upcoming classes'),
                    );
                  }
                  return Column(
                    children:
                        classes.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final classDate = data['date'] ?? '';
                          final classTime = data['time'] ?? '';
                          final jitsiRoom = data['jitsiRoom'] ?? '';
                          final teacherJoined = data['teacherJoined'] ?? false;
                          final classDateTime = parseClassDateTime(
                            classDate,
                            classTime,
                          );
                          // Check if class is within the joinable window (5 minutes before to 10 minutes after)
                          final canJoin =
                              classDateTime != null &&
                              DateTime.now().isAfter(
                                classDateTime.subtract(
                                  const Duration(minutes: 5),
                                ),
                              ) &&
                              DateTime.now().isBefore(
                                classDateTime.add(const Duration(minutes: 10)),
                              );
                          // Class is completed only after 10 minutes AND teacher joined
                          final isCompleted =
                              teacherJoined &&
                              classDateTime != null &&
                              DateTime.now().isAfter(
                                classDateTime.add(const Duration(minutes: 10)),
                              );
                          // Class is missed if teacher never joined and it's past the 10-minute window
                          final isMissed =
                              !teacherJoined &&
                              classDateTime != null &&
                              DateTime.now().isAfter(
                                classDateTime.add(const Duration(minutes: 10)),
                              );

                          return Card(
                            elevation: 2,
                            color: Theme.of(context).cardColor,
                            shadowColor: Theme.of(context).shadowColor,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFe5faf3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(Iconsax.teacher, color: appGreen),
                              ),
                              title: FutureBuilder<DocumentSnapshot>(
                                future:
                                    (data['studentId'] != null)
                                        ? FirebaseFirestore.instance
                                            .collection('students')
                                            .doc(data['studentId'])
                                            .get()
                                        : null,
                                builder: (context, studentSnapshot) {
                                  String studentName = 'Student';
                                  if (studentSnapshot.hasData &&
                                      studentSnapshot.data!.exists) {
                                    final studentData =
                                        studentSnapshot.data!.data()
                                            as Map<String, dynamic>?;
                                    studentName =
                                        studentData?['fullName'] ?? 'Student';
                                  }
                                  return Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                              subtitle: Builder(
                                builder: (context) {
                                  DateTime? localDateTime;
                                  if (data['scheduledAt'] != null) {
                                    // scheduledAt is a Firestore Timestamp
                                    localDateTime =
                                        (data['scheduledAt'] as Timestamp)
                                            .toDate()
                                            .toLocal();
                                  } else {
                                    // fallback for old data
                                    localDateTime = parseClassDateTime(
                                      classDate,
                                      classTime,
                                    );
                                  }
                                  final displayTime =
                                      localDateTime != null
                                          ? TimeOfDay.fromDateTime(
                                            localDateTime,
                                          ).format(context)
                                          : classTime;
                                  final displayDate =
                                      localDateTime != null
                                          ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(localDateTime)
                                          : classDate;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(displayTime),
                                      Text(displayDate),
                                    ],
                                  );
                                },
                              ),
                              trailing:
                                  isMissed
                                      ? const Text(
                                        'Missed',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : isCompleted
                                      ? const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : OutlinedButton(
                                        onPressed:
                                            (canJoin && jitsiRoom.isNotEmpty)
                                                ? () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('classes')
                                                      .doc(doc.id)
                                                      .update({
                                                        'teacherJoined': true,
                                                        'teacherJoinTime':
                                                            FieldValue.serverTimestamp(),
                                                      });
                                                  // Send notification to student
                                                  final studentId =
                                                      data['studentId'] ?? '';
                                                  final teacherName =
                                                      data['teacherName'] ?? '';
                                                  final studentName =
                                                      data['studentName'] ?? '';
                                                  final classId = doc.id;
                                                  if (studentId.isNotEmpty) {
                                                    await NotificationService.sendJoinWaitingNotification(
                                                      receiverId: studentId,
                                                      senderName: teacherName,
                                                      senderRole: 'teacher',
                                                      classId: classId,
                                                    );
                                                  }
                                                  joinJitsiMeeting(jitsiRoom);
                                                }
                                                : null,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                          backgroundColor:
                                              canJoin
                                                  ? appGreen
                                                  : (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors
                                                          .grey
                                                          .shade700 // Dark mode border color
                                                      : Colors.grey.shade300),
                                          foregroundColor:
                                              canJoin
                                                  ? Colors.white
                                                  : (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white70
                                                      : Colors.black26),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          teacherJoined
                                              ? 'Rejoin'
                                              : 'Join Class',
                                        ),
                                      ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScheduleClassesScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Schedule Class',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
