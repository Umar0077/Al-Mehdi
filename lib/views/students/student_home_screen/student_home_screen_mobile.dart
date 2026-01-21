import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/home/student_home_view_mobile_provider.dart';
import '../../../services/notification_service.dart';
import '../student_attendance/student_attendance.dart';
import '../student_notifications/student_notifications.dart';

class StudentHomeScreenMobile extends StatelessWidget {
  const StudentHomeScreenMobile({super.key});

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
    return ChangeNotifierProvider<StudentHomeViewMobileProvider>(
      create: (_) => StudentHomeViewMobileProvider(),
      child: Consumer<StudentHomeViewMobileProvider>(
        builder: (context, provider, _) {
          final fullName = provider.fullName;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fullName != null
                            ? '👋 Welcome, $fullName!'
                            : '👋 Welcome, Student!',
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
                                  builder: (_) => StudentNotificationScreen(),
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
                  const SizedBox(width: 4),
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
                                  style: TextButton.styleFrom(
                                    foregroundColor: appGreen,
                                  ),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    // Recent Chats Section
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('students')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get(),
                      builder: (context, studentSnapshot) {
                        if (studentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (studentSnapshot.hasError ||
                            !studentSnapshot.hasData ||
                            !studentSnapshot.data!.exists) {
                          return Card(
                            elevation: 2,
                            color: Theme.of(context).cardColor,
                            shadowColor: Theme.of(context).shadowColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'No conversation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Student not found',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final assignedTeacherId =
                            studentSnapshot.data!['assignedTeacherId'];
                        if (assignedTeacherId == null) {
                          return Card(
                            elevation: 2,
                            color: Theme.of(context).cardColor,
                            shadowColor: Theme.of(context).shadowColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'No conversation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'No teacher assigned',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('chatRooms')
                                  .where(
                                    'participants',
                                    arrayContains: assignedTeacherId,
                                  )
                                  .orderBy('updatedAt', descending: true)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, chatSnapshot) {
                            if (chatSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (chatSnapshot.hasError ||
                                !chatSnapshot.hasData ||
                                chatSnapshot.data!.docs.isEmpty) {
                              return Card(
                                elevation: 2,
                                color: Theme.of(context).cardColor,
                                shadowColor: Theme.of(context).shadowColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFe5faf3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Iconsax.user,
                                          color: appGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'No conversation',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'No conversations found',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              '',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final chatData =
                                chatSnapshot.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            final lastMessage =
                                chatData['lastMessage'] ??
                                'Click to start chatting';
                            final lastMessageTime =
                                chatData['lastMessageTime'] as Timestamp?;
                            final teacherName = chatData['teacherName'] ?? '';
                            String timeText = 'Now';
                            if (lastMessageTime != null) {
                              final now = DateTime.now();
                              final messageTime = lastMessageTime.toDate();
                              final difference = now.difference(messageTime);
                              if (difference.inMinutes < 1) {
                                timeText = 'Now';
                              } else if (difference.inMinutes < 60) {
                                timeText = '${difference.inMinutes}m ago';
                              } else if (difference.inHours < 24) {
                                timeText = '${difference.inHours}h ago';
                              } else {
                                timeText =
                                    '${messageTime.day}/${messageTime.month}/${messageTime.year}';
                              }
                            }
                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  teacherName.isEmpty
                                      ? FirebaseFirestore.instance
                                          .collection('teachers')
                                          .doc(assignedTeacherId)
                                          .get()
                                      : null,
                              builder: (context, teacherSnap) {
                                String displayTeacherName = teacherName;
                                if (teacherName.isEmpty &&
                                    teacherSnap.hasData &&
                                    teacherSnap.data!.exists) {
                                  final data =
                                      teacherSnap.data!.data()
                                          as Map<String, dynamic>;
                                  displayTeacherName =
                                      data['fullName'] ?? 'Teacher';
                                } else if (teacherName.isEmpty) {
                                  displayTeacherName = 'Teacher';
                                }
                                return Card(
                                  elevation: 2,
                                  color: Theme.of(context).cardColor,
                                  shadowColor: Theme.of(context).shadowColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFe5faf3),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Iconsax.user,
                                            color: appGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayTeacherName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lastMessage,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timeText,
                                                style: const TextStyle(
                                                  fontSize: 14,
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
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentAttendanceScreen(),
                          ),
                        );
                      },
                      child: FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('classes')
                                .where(
                                  'studentId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid,
                                )
                                .where('status', isEqualTo: 'completed')
                                .get(),
                        builder: (context, snapshot) {
                          Widget subtitleWidget;
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            subtitleWidget = const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 14),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            subtitleWidget = const Text(
                              '0 / 0 Classes Attended',
                              style: TextStyle(fontSize: 14),
                            );
                          } else {
                            final docs = snapshot.data!.docs;
                            final y = docs.length;
                            final x =
                                docs
                                    .where(
                                      (doc) =>
                                          (doc.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >)['attendanceStatus'] ==
                                          'present',
                                    )
                                    .length;
                            subtitleWidget = Text(
                              '$x / $y Classes Attended',
                              style: const TextStyle(fontSize: 14),
                            );
                          }
                          return _InfoCard(
                            icon: Icons.bar_chart,
                            title: 'Attendance',
                            subtitleWidget: subtitleWidget,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Active Classes Section
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('classes')
                              .where(
                                'studentId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final now = DateTime.now();
                        final activeClasses =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              DateTime? classDateTime;
                              if (data['scheduledAt'] != null) {
                                classDateTime =
                                    (data['scheduledAt'] as Timestamp)
                                        .toDate()
                                        .toLocal();
                              } else {
                                final date = data['date'] as String?;
                                final time = data['time'] as String?;
                                classDateTime = parseClassDateTime(date, time);
                              }
                              final joinWindowStart = classDateTime?.subtract(
                                const Duration(minutes: 5),
                              );
                              final joinWindowEnd = classDateTime?.add(
                                const Duration(minutes: 10),
                              );

                              return classDateTime != null &&
                                  joinWindowStart != null &&
                                  joinWindowEnd != null &&
                                  now.isAfter(joinWindowStart) &&
                                  now.isBefore(joinWindowEnd);
                            }).toList();

                        if (activeClasses.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'Active Classes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...activeClasses.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final teacher = data['teacherName'] ?? 'Teacher';
                              final jitsiRoom = data['jitsiRoom'] ?? '';
                              final studentJoined =
                                  data['studentJoined'] ?? false;

                              return Card(
                                color: Theme.of(context).cardColor,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe5faf3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Iconsax.teacher,
                                      color: appGreen,
                                    ),
                                  ),
                                  title: Text(
                                    teacher,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Builder(
                                    builder: (context) {
                                      DateTime? localDateTime;
                                      String classDate = '';
                                      String classTime = '';

                                      if (data['scheduledAt'] != null) {
                                        // scheduledAt is a Firestore Timestamp
                                        localDateTime =
                                            (data['scheduledAt'] as Timestamp)
                                                .toDate()
                                                .toLocal();
                                      } else {
                                        // fallback for old data
                                        classDate = data['date'] ?? '';
                                        classTime = data['time'] ?? '';
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
                                              : (classTime.isNotEmpty
                                                  ? classTime
                                                  : 'No time available');
                                      final displayDate =
                                          localDateTime != null
                                              ? DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(localDateTime)
                                              : (classDate.isNotEmpty
                                                  ? classDate
                                                  : 'No date available');
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
                                  trailing: OutlinedButton(
                                    onPressed:
                                        jitsiRoom.isNotEmpty
                                            ? () async {
                                              try {
                                                final options =
                                                    JitsiMeetConferenceOptions(
                                                      room: jitsiRoom,
                                                      userInfo:
                                                          JitsiMeetUserInfo(
                                                            displayName:
                                                                fullName ??
                                                                'Student',
                                                          ),
                                                      featureFlags: {
                                                        "welcomepage.enabled":
                                                            false,
                                                        "startWithAudioMuted":
                                                            false,
                                                        "startWithVideoMuted":
                                                            false,
                                                      },
                                                    );
                                                await JitsiMeet().join(options);
                                                // Update join time and joined status if not already joined
                                                if (!studentJoined) {
                                                  await FirebaseFirestore
                                                      .instance
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
                                                }
                                              } catch (e) {
                                                // Optionally show error
                                              }
                                            }
                                            : null,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.transparent,
                                      ),
                                      backgroundColor:
                                          jitsiRoom.isNotEmpty
                                              ? appGreen
                                              : Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      studentJoined ? 'Rejoin' : 'Join Class',
                                      style: TextStyle(
                                        color:
                                            jitsiRoom.isNotEmpty
                                                ? Colors.white
                                                : Colors.black26,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                    const Text(
                      'Your Upcoming Classes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Upcoming Classes Section
                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('classes')
                              .where(
                                'studentId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              // .where('status', isEqualTo: 'upcoming') // Remove this filter!
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48.0),
                            child: Center(child: Text('No upcoming classes')),
                          );
                        }
                        final now = DateTime.now();
                        final classes =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              DateTime? classDateTime;
                              if (data['scheduledAt'] != null) {
                                classDateTime =
                                    (data['scheduledAt'] as Timestamp)
                                        .toDate()
                                        .toLocal();
                              } else {
                                final date = data['date'] as String?;
                                final time = data['time'] as String?;
                                classDateTime = parseClassDateTime(date, time);
                              }
                              final joinWindowEnd = classDateTime?.add(
                                const Duration(minutes: 10),
                              );
                              // Show all upcoming classes (that haven't ended their join window)
                              return classDateTime != null &&
                                  now.isBefore(joinWindowEnd!);
                            }).toList();
                        classes.sort((a, b) {
                          DateTime getDateTime(QueryDocumentSnapshot doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final date = data['date'] as String?;
                            final time = data['time'] as String?;
                            final dt = parseClassDateTime(date, time);
                            return dt ?? DateTime(1970);
                          }

                          return getDateTime(a).compareTo(getDateTime(b));
                        });
                        if (classes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Center(child: Text('No upcoming classes')),
                          );
                        }
                        return Column(
                          children:
                              classes.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final classDate = data['date'] ?? '';
                                final classTime = data['time'] ?? '';
                                final teacher =
                                    data['teacherName'] ?? 'Teacher';
                                final jitsiRoom = data['jitsiRoom'] ?? '';
                                final studentJoined =
                                    data['studentJoined'] ?? false;
                                final classDateTime = parseClassDateTime(
                                  classDate,
                                  classTime,
                                );
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
                                    now.isAfter(
                                      classDateTime.add(
                                        const Duration(minutes: 10),
                                      ),
                                    );
                                return Card(
                                  color: Theme.of(context).cardColor,
                                  shadowColor: Theme.of(context).shadowColor,
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe5faf3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Iconsax.teacher,
                                        color: appGreen,
                                      ),
                                    ),
                                    title: Text(
                                      teacher,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
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
                                                : (classTime ??
                                                    'No time available');
                                        final displayDate =
                                            localDateTime != null
                                                ? DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(localDateTime)
                                                : (classDate ??
                                                    'No date available');
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
                                        isCompleted
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
                                                  (canJoin &&
                                                          jitsiRoom.isNotEmpty)
                                                      ? () async {
                                                        try {
                                                          final options = JitsiMeetConferenceOptions(
                                                            room: jitsiRoom,
                                                            userInfo:
                                                                JitsiMeetUserInfo(
                                                                  displayName:
                                                                      fullName ??
                                                                      'Student',
                                                                ),
                                                            featureFlags: {
                                                              "welcomepage.enabled":
                                                                  false,
                                                              "startWithAudioMuted":
                                                                  false,
                                                              "startWithVideoMuted":
                                                                  false,
                                                            },
                                                          );
                                                          await JitsiMeet()
                                                              .join(options);
                                                          // Update join time and student joined status
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'classes',
                                                              )
                                                              .doc(doc.id)
                                                              .update({
                                                                'studentJoined':
                                                                    true,
                                                                'studentJoinTime':
                                                                    FieldValue.serverTimestamp(),
                                                              });
                                                        } catch (e) {
                                                          // Optionally show error
                                                        }
                                                      }
                                                      : null,
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
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
                                                            : Colors
                                                                .grey
                                                                .shade300),
                                                foregroundColor:
                                                    canJoin
                                                        ? Colors.white
                                                        : (Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors
                                                                .white70 // Lighter text in dark mode when disabled
                                                            : Colors.black26),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Text(
                                                studentJoined
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
                    if (provider.joinableClass != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child:
                            provider.hasJoined
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Joined',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                : ElevatedButton(
                                  onPressed:
                                      provider.jitsiInitialized
                                          ? () =>
                                              provider.joinJitsiMeeting(context)
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Join Class',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
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
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? subtitleWidget;

  const _InfoCard({
    required this.icon,
    required this.title,
    this.subtitleWidget,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFe5faf3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: appGreen),
            ),
            const SizedBox(width: 12),
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
                  subtitleWidget ?? const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
