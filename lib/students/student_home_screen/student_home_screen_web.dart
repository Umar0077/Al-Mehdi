import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../components/student_sidebar.dart';
import '../student_attendance/student_attendance.dart';
// import '../student_chat/student_chat_web.dart';
import '../student_notifications/student_notifications.dart';
import '../student_classes/student_classes.dart';
import '../student_chat/student_chat.dart';
import '../student_settings/student_settings.dart';
import '../../views/auth_views/login_screen.dart';
import '../student_profile/student_profile.dart';
import '../../services/notification_service.dart';
import 'package:al_mehdi_online_school/teachers/teacher_chat/chats.dart' as teacher_chat;
import 'student_home_screen_web_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

// Helper function to detect mobile browsers
bool _isMobileBrowser() { // ignore: unused_element
  try {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('mobile') || 
           userAgent.contains('android') || 
           userAgent.contains('iphone') || 
           userAgent.contains('ipad');
  } catch (e) {
    // If dart:html is not available, assume desktop
    return false;
  }
}

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

class StudentHomeScreenWeb extends StatelessWidget {
  const StudentHomeScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentHomeScreenWebProvider>(
      create: (_) => StudentHomeScreenWebProvider(),
      child: Consumer<StudentHomeScreenWebProvider>(
        builder: (context, provider, _) {
          final List<Widget> screens = [
            _StudentHomeContent(
              fullName: provider.fullName,
              assignedTeacherId: provider.assignedTeacherId,
              onTapRecentConversation: provider.assignedTeacherId != null ? () => provider.navigateToChatTab() : null,
              onTapAttendanceTab: () => provider.setSelectedIndex(2),
            ),
            const StudentClassesScreen(),
            const StudentAttendanceScreen(),
            const StudentChatScreen(),
            const StudentSettingsScreen(),
            const StudentProfileScreen(),
          ];
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                StudentSidebar(
                  selectedIndex: provider.selectedIndex,
                  onItemSelected: (index) {
                    provider.setSelectedIndex(index);
                  },
                ),
                Expanded(
                  child: IndexedStack(index: provider.selectedIndex, children: screens),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHomeContent extends StatelessWidget {
  final String? fullName;
  final String? assignedTeacherId;
  final VoidCallback? onTapRecentConversation;
  final VoidCallback? onTapAttendanceTab;
  const _StudentHomeContent({
    this.fullName,
    this.assignedTeacherId,
    this.onTapRecentConversation,
    this.onTapAttendanceTab,
  });
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentHomeScreenWebProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fullName != null ? '👋 Welcome, $fullName!' : '👋 Welcome, Student!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                              builder: (context) => StudentNotificationScreen(),
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
                backgroundImage: provider.profilePictureUrl != null
                    ? NetworkImage(provider.profilePictureUrl!)
                    : null,
                child: provider.profilePictureUrl == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Do you really want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(foregroundColor: appGreen),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: appGreen, foregroundColor: Colors.white),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                              ? 'Welcome back, $fullName! Your next class starts soon.'
                              : 'Welcome back, Student! Your next class starts soon.',
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
                                    if (onTapAttendanceTab != null) {
                                      onTapAttendanceTab!.call();
                                    }
                                  },
                                  child: const Text(
                                    "Details",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Real-time x/y classes attended
                            FutureBuilder<QuerySnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('classes')
                                      .where(
                                        'studentId',
                                        isEqualTo:
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                      )
                                      .where('status', isEqualTo: 'completed')
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
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '0 / 0 Classes Attended',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }
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
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '$x / $y Classes Attended',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Great progress this week! 🎉',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: provider.showChat && provider.chatData != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => provider.setShowChat(false),
                                ),
                                const Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: teacher_chat.ChatConversation(
                                chat: provider.chatData!,
                                showHeader: true,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 0),
                              // Active Classes Section
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('classes')
                                    .where(
                                      'studentId',
                                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                                    )
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final now = DateTime.now();
                                  final activeClasses = snapshot.data!.docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    DateTime? classDateTime;
                                    if (data['scheduledAt'] != null) {
                                      classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
                                    } else {
                                      final date = data['date'] ?? '';
                                      final time = data['time'] ?? '';
                                      classDateTime = parseClassDateTime(date, time);
                                    }
                                    final joinWindowStart = classDateTime?.subtract(const Duration(minutes: 5));
                                    final joinWindowEnd = classDateTime?.add(const Duration(minutes: 10));
                                    
                                    // Show classes that are currently in the active window (5 min before to 10 min after)
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
                                      const Text(
                                        'Active Classes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        children: activeClasses.map((doc) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final teacher = data['teacherName'] ?? 'Teacher';
                                          final classDate = data['date'] ?? '';
                                          final classTime = data['time'] ?? '';
                                          final jitsiRoom = data['jitsiRoom'] ?? '';
                                          final studentJoined = data['studentJoined'] ?? false;
                                          final scheduledAt = data['scheduledAt'];
                                          
                                          DateTime? localDateTime;
                                          if (scheduledAt != null) {
                                            localDateTime = (scheduledAt as Timestamp).toDate().toLocal();
                                          } else {
                                            localDateTime = parseClassDateTime(classDate, classTime);
                                          }
                                          final displayTime = localDateTime != null
                                              ? TimeOfDay.fromDateTime(localDateTime).format(context)
                                              : classTime;
                                          final displayDate = localDateTime != null
                                              ? DateFormat('yyyy-MM-dd').format(localDateTime)
                                              : classDate;

                                          return _WebClassCard(
                                            title: teacher,
                                            time: displayTime,
                                            teacher: displayDate,
                                            text: studentJoined ? 'Rejoin' : 'Join Class',
                                            roomName: jitsiRoom,
                                            canJoin: true, // Active classes always have green buttons
                                            onJoin: jitsiRoom.isNotEmpty
                                                ? () async {
                                                  try {
                                                    final url = 'https://meet.jit.si/$jitsiRoom';
                                                    
                                                    await _launchJitsiMeeting(url);
                                                    
                                                    // Only update studentJoined if not already joined
                                                    if (!studentJoined) {
                                                      await FirebaseFirestore.instance
                                                          .collection('classes')
                                                          .doc(doc.id)
                                                          .update({
                                                            'studentJoined': true,
                                                            'studentJoinTime': FieldValue.serverTimestamp(),
                                                          });
                                                      // Send notification to teacher
                                                      final teacherId = data['teacherId'] ?? '';
                                                      // teacherName not used here
                                                      final studentName = data['studentName'] ?? '';
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
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                },
                              ),
                              const Text(
                                'Your Upcoming Classes',
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
                                          'studentId',
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
                                        final date = data['date'];
                                        final time = data['time'];
                                        DateTime? classDateTime;
                                        try {
                                          final parts = date.split('/');
                                          if (parts.length == 3) {
                                            final month = int.parse(parts[0]);
                                            final day = int.parse(parts[1]);
                                            final year = int.parse(parts[2]);
                                            final time24 = _parseTimeTo24Hour(
                                              time,
                                            );
                                            final timeParts = time24.split(
                                              ':',
                                            );
                                            final hour = int.parse(
                                              timeParts[0],
                                            );
                                            final minute = int.parse(
                                              timeParts[1],
                                            );
                                            classDateTime = DateTime(
                                              year,
                                              month,
                                              day,
                                              hour,
                                              minute,
                                            );
                                          }
                                        } catch (_) {
                                          classDateTime = null;
                                        }
                                        // Show all classes that haven't ended their join window yet (10 minutes after)
                                        return classDateTime != null &&
                                            now.isBefore(classDateTime.add(const Duration(minutes: 10)));
                                      }).toList();

                                  // Sort by classDateTime ascending
                                  classes.sort((a, b) {
                                    DateTime getDateTime(
                                      QueryDocumentSnapshot doc,
                                    ) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final date = data['date'];
                                      final time = data['time'];
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
                                          final teacher =
                                              data['teacherName'] ??
                                              'Teacher';
                                          final classDate =
                                              data['date'] ?? '';
                                          final classTime =
                                              data['time'] ?? '';
                                          final jitsiRoom =
                                              data['jitsiRoom'] ?? '';
                                          final studentJoined =
                                              data['studentJoined'] ?? false;
                                          final scheduledAt = data['scheduledAt'];
                                          DateTime? localDateTime;
                                          if (scheduledAt != null) {
                                            // scheduledAt is a Firestore Timestamp
                                            localDateTime = (scheduledAt as Timestamp).toDate().toLocal();
                                          } else {
                                            // fallback for old data
                                            localDateTime = parseClassDateTime(classDate, classTime);
                                          }
                                          final displayTime = localDateTime != null
                                              ? TimeOfDay.fromDateTime(localDateTime).format(context)
                                              : classTime;
                                          final displayDate = localDateTime != null
                                              ? DateFormat('yyyy-MM-dd').format(localDateTime)
                                              : classDate;

                                          final classDateTime =
                                              parseClassDateTime(
                                                classDate,
                                                classTime,
                                              );
                                          final now = DateTime.now();

                                          // Check if class is within the joinable window (5 minutes before to 10 minutes after)
                                          final canJoin = classDateTime != null &&
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

                                          // Class is completed only after 10 minutes AND student joined
                                          final isCompleted = studentJoined &&
                                              classDateTime != null &&
                                              now.isAfter(
                                                classDateTime.add(
                                                  const Duration(minutes: 10),
                                                ),
                                              );
                                          
                                          // Class is missed if student never joined and it's past the 10-minute window
                                          final isMissed = !studentJoined &&
                                              classDateTime != null &&
                                              now.isAfter(
                                                classDateTime.add(
                                                  const Duration(minutes: 10),
                                                ),
                                              );
                                          return _WebClassCard(
                                            title: teacher,
                                            time: displayTime,
                                            teacher: displayDate,
                                            text: isMissed
                                                ? 'Missed'
                                                : isCompleted
                                                ? 'Completed'
                                                : (studentJoined ? 'Rejoin' : 'Join Class'),
                                            roomName: jitsiRoom,
                                            canJoin: canJoin, // Pass the canJoin status for button color
                                            onJoin: (canJoin && jitsiRoom.isNotEmpty)
                                                ? () async {
                                                    // Open Jitsi in new tab
                                                    final url = 'https://meet.jit.si/$jitsiRoom';
                                                    await _launchJitsiMeeting(url);
                                                    
                                                    // Update studentJoined status and track join time
                                                    await FirebaseFirestore.instance
                                                        .collection('classes')
                                                        .doc(doc.id)
                                                        .update({
                                                          'studentJoined': true,
                                                          'studentJoinTime': FieldValue.serverTimestamp(),
                                                        });
                                                    
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('You have joined the class!')),
                                                      );
                                                    }
                                                  }
                                                : null,
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
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('students')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .get(),
                                builder: (context, studentSnapshot) {
                                  if (studentSnapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }
                                  if (studentSnapshot.hasError || !studentSnapshot.hasData || !studentSnapshot.data!.exists) {
                                    return _WebConversationCard(
                                      name: 'No conversation',
                                      message: 'Student not found',
                                      time: '',
                                    );
                                  }
                                  final assignedTeacherId = studentSnapshot.data!['assignedTeacherId'];
                                  if (assignedTeacherId == null) {
                                    return _WebConversationCard(
                                      name: 'No conversation',
                                      message: 'No teacher assigned',
                                      time: '',
                                    );
                                  }
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('chatRooms')
                                        .where('participants', arrayContains: assignedTeacherId)
                                        .orderBy('updatedAt', descending: true)
                                        .limit(1)
                                        .snapshots(),
                                    builder: (context, chatSnapshot) {
                                      if (chatSnapshot.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (chatSnapshot.hasError || !chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                                        return _WebConversationCard(
                                          name: 'No conversation',
                                          message: 'No conversations found',
                                          time: '',
                                        );
                                      }
                                      final chatRoom = chatSnapshot.data!.docs.first;
                                      final chatDataMap = chatRoom.data() as Map<String, dynamic>;
                                      final lastMessage = chatDataMap['lastMessage'] ?? 'Click to start chatting';
                                      final lastMessageTime = chatDataMap['lastMessageTime'] as Timestamp?;
                                      String teacherName = chatDataMap['teacherName'] ?? '';
                                      // If teacherName is missing, fetch from teachers collection
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: teacherName.isEmpty
                                            ? FirebaseFirestore.instance.collection('teachers').doc(assignedTeacherId).get()
                                            : null,
                                        builder: (context, teacherSnap) {
                                          String displayTeacherName = teacherName;
                                          if (teacherName.isEmpty && teacherSnap.hasData && teacherSnap.data!.exists) {
                                            final data = teacherSnap.data!.data() as Map<String, dynamic>;
                                            displayTeacherName = data['fullName'] ?? 'Teacher';
                                          } else if (teacherName.isEmpty) {
                                            displayTeacherName = 'Teacher';
                                          }
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
                                              timeText = '${messageTime.day}/${messageTime.month}/${messageTime.year}';
                                            }
                                          }
                                          // teacherAvatar not used in this layout
                                          return GestureDetector(
                                            onTap: () {
                                              final provider = Provider.of<StudentHomeScreenWebProvider>(context, listen: false);
                                              provider.setSelectedIndex(3); // 3 is the chat tab index
                                            },
                                            child: _WebConversationCard(
                                              name: displayTeacherName,
                                              message: lastMessage,
                                              time: timeText,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
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
                  Widget trailingWidget;
                  if (text == 'Missed') {
                    trailingWidget = const Text(
                      'Missed',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else if (text == 'Joined') {
                    trailingWidget = const Text(
                      'Joined',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    trailingWidget = OutlinedButton(
                      onPressed: onJoin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.transparent),
                        backgroundColor:
                            canJoin ? appGreen : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700 // Dark mode border color
                                : Colors.grey.shade300),
                        foregroundColor:
                            canJoin
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70 // Lighter text in dark mode when disabled
                                : Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(text),
                    );
                  }

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
                          child: trailingWidget,
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
                        SizedBox(width: double.infinity, child: trailingWidget),
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

String _parseTimeTo24Hour(String time) {
  final timeReg = RegExp(r'(\d{1,2}):(\d{2})\s*([AP]M)', caseSensitive: false);
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

// Utility function for parsing date and time to DateTime
DateTime? parseClassDateTime(String date, String time) {
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
