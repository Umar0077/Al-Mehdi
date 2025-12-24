import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../services/notification_service.dart';

// Helper function to open URLs in a platform-agnostic way
Future<void> _openUrl(String url) async {
  if (kIsWeb) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class StudentClassesMobileView extends StatelessWidget {
  const StudentClassesMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Classes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              alignment: Alignment.centerLeft,
              child: TabBar(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: appGreen),
                  insets: const EdgeInsets.symmetric(horizontal: 16),
                ),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Missed'),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: TabBarView(
            children: [
              _UpcomingClassesMobileTab(),
              _CompletedClassesMobileTab(),
              _MissedClassesMobileTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// UPCOMING TAB
class _UpcomingClassesMobileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
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
              child: Text(
                'No upcoming classes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final classes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          DateTime? classDateTime;
          if (data['scheduledAt'] != null) {
            classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
          } else {
            final date = data['date'];
            final time = data['time'];
            try {
              final parts = date.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(time);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            } catch (_) {
              classDateTime = null;
            }
          }
          final joinWindowEnd = classDateTime?.add(const Duration(minutes: 10));
          // Show all classes that haven't ended their join window yet
          return classDateTime != null && now.isBefore(joinWindowEnd!);
        }).toList();

        classes.sort((a, b) {
          DateTime getDateTime(QueryDocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['scheduledAt'] != null) {
              return (data['scheduledAt'] as Timestamp).toDate().toLocal();
            }
            final date = data['date'];
            final time = data['time'];
            final parts = date.split('/');
            if (parts.length == 3) {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final time24 = _parseTimeTo24Hour(time);
              final timeParts = time24.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              return DateTime(year, month, day, hour, minute);
            }
            return DateTime(1970);
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
          shrinkWrap: true,
          children: classes.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final teacher = data['teacherName'] ?? 'Teacher';
            final jitsiRoom = data['jitsiRoom'] ?? '';
            final studentJoined = data['studentJoined'] ?? false;

            DateTime? classDateTime;
            if (data['scheduledAt'] != null) {
              classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
            } else {
              final classDate = data['date'] ?? '';
              final classTime = data['time'] ?? '';
              final parts = classDate.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(classTime);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            }

            final now = DateTime.now();
            final joinWindowStart = classDateTime?.subtract(const Duration(minutes: 5));
            final joinWindowEnd = classDateTime?.add(const Duration(minutes: 10));
            
            final isInJoinWindow = classDateTime != null &&
                joinWindowStart != null &&
                joinWindowEnd != null &&
                now.isAfter(joinWindowStart) &&
                now.isBefore(joinWindowEnd);
            
            final canJoin = isInJoinWindow;
            final isCompleted = classDateTime != null &&
                now.isAfter(classDateTime.add(const Duration(minutes: 10)));
            final isMissed = !studentJoined && isCompleted;

            final displayTime = classDateTime != null
                ? TimeOfDay.fromDateTime(classDateTime).format(context)
                : (data['time'] ?? '');
            final displayDate = classDateTime != null
                ? DateFormat('yyyy-MM-dd').format(classDateTime)
                : (data['date'] ?? '');

            return Card(
              elevation: 2,
              color: Theme.of(context).scaffoldBackgroundColor,
              shadowColor: Theme.of(context).shadowColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  teacher,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(displayTime), Text(displayDate)],
                ),
                trailing: isMissed
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
                            onPressed: canJoin && jitsiRoom.isNotEmpty
                                ? () async {
                                    // 1. Launch Jitsi meeting (mobile only)
                                    if (!kIsWeb) {
                                      final options = JitsiMeetConferenceOptions(
                                        room: jitsiRoom,
                                        userInfo: JitsiMeetUserInfo(
                                          displayName: teacher,
                                        ),
                                        featureFlags: {
                                          "welcomepage.enabled": false,
                                          "startWithAudioMuted": false,
                                          "startWithVideoMuted": false,
                                        },
                                      );
                                      await JitsiMeet().join(options);
                                    } else {
                                      // For web, open in browser
                                      await _openUrl('https://meet.jit.si/$jitsiRoom');
                                    }
                                    // 2. Mark as joined in Firestore
                                    await FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(doc.id)
                                        .update({
                                          'studentJoined': true,
                                          'studentJoinTime': FieldValue.serverTimestamp(),
                                        });
                                    // Send notification to teacher
                                    final teacherId = data['teacherId'] ?? '';
                                    final teacherName = data['teacherName'] ?? '';
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
                                    // 3. Optionally show feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You have joined the class!')),
                                    );
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  canJoin ? appGreen : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700 // Dark mode border color
                                : Colors.grey.shade300), // Light mode border color
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              studentJoined && isInJoinWindow ? 'Rejoin' : 'Join',
                              style: TextStyle(
                                color: canJoin
                                ? Colors.white // White text when can join
                                : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70 // Lighter text in dark mode when disabled
                                : Colors.black26), // Dark text when in light mode
                              ),
                            ),
                          ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// COMPLETED TAB
class _CompletedClassesMobileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
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
              child: Text(
                'No completed classes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final completedClasses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final studentJoined = data['studentJoined'] ?? false;
          DateTime? classDateTime;
          if (data['scheduledAt'] != null) {
            classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
          } else {
            final date = data['date'];
            final time = data['time'];
            try {
              final parts = date.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(time);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            } catch (_) {
              classDateTime = null;
            }
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
          children: completedClasses.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final teacher = data['teacherName'] ?? 'Teacher';
            DateTime? classDateTime;
            if (data['scheduledAt'] != null) {
              classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
            } else {
              final classDate = data['date'] ?? '';
              final classTime = data['time'] ?? '';
              final parts = classDate.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(classTime);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            }
            final displayTime = classDateTime != null
                ? TimeOfDay.fromDateTime(classDateTime).format(context)
                : (data['time'] ?? '');
            final displayDate = classDateTime != null
                ? DateFormat('yyyy-MM-dd').format(classDateTime)
                : (data['date'] ?? '');
            return Card(
              elevation: 2,
              color: Theme.of(context).scaffoldBackgroundColor,
              shadowColor: Theme.of(context).shadowColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  teacher,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayTime),
                    Text(displayDate),
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
            );
          }).toList(),
        );
      },
    );
  }
}

// MISSED TAB
class _MissedClassesMobileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
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
              child: Text(
                'No missed classes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final missedClasses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          DateTime? classDateTime;
          if (data['scheduledAt'] != null) {
            classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
          } else {
            final date = data['date'];
            final time = data['time'];
            try {
              final parts = date.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(time);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            } catch (_) {
              classDateTime = null;
            }
          }
          final studentJoined = data['studentJoined'] ?? false;
          final missedThreshold = classDateTime?.add(const Duration(minutes: 10));
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
          children: missedClasses.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final teacher = data['teacherName'] ?? 'Teacher';
            DateTime? classDateTime;
            if (data['scheduledAt'] != null) {
              classDateTime = (data['scheduledAt'] as Timestamp).toDate().toLocal();
            } else {
              final classDate = data['date'] ?? '';
              final classTime = data['time'] ?? '';
              final parts = classDate.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final time24 = _parseTimeTo24Hour(classTime);
                final timeParts = time24.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                classDateTime = DateTime(year, month, day, hour, minute);
              }
            }
            final displayTime = classDateTime != null
                ? TimeOfDay.fromDateTime(classDateTime).format(context)
                : (data['time'] ?? '');
            final displayDate = classDateTime != null
                ? DateFormat('yyyy-MM-dd').format(classDateTime)
                : (data['date'] ?? '');
            return Card(
              elevation: 2,
              color: Theme.of(context).scaffoldBackgroundColor,
              shadowColor: Theme.of(context).shadowColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  teacher,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayTime),
                    Text(displayDate),
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
            );
          }).toList(),
        );
      },
    );
  }
}

// Helper function for time parsing
String _parseTimeTo24Hour(String time) {
  final timeRegExp = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false);
  final match = timeRegExp.firstMatch(time);
  if (match != null) {
    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  return time;
}

// Dummy ClassesList for demonstration (replace with your actual implementation)
class ClassesList extends StatelessWidget {
  final String type;
  final Query Function(String userId)? queryBuilder;
  const ClassesList({super.key, required this.type, this.queryBuilder});
  @override
  Widget build(BuildContext context) {
    // Your implementation here
    return Container();
  }
}
