import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/teachers/classes/teacher_classes_mobile_provider.dart';
import '../../../services/notification_service.dart';
import '../teacher_schedule_class/teacher_schedule_class.dart';

class TeacherClassesMobileView extends StatelessWidget {
  const TeacherClassesMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherClassesMobileProvider>(
      create: (_) => TeacherClassesMobileProvider(),
      child: Consumer<TeacherClassesMobileProvider>(
        builder: (context, provider, _) {
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Classes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          MediaQuery.of(context).size.width < 400 ? 20 : 24,
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            MediaQuery.of(context).size.width < 400 ? 16 : 18,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize:
                            MediaQuery.of(context).size.width < 400 ? 14 : 16,
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
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 400 ? 12 : 24,
                  vertical: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildClassesList(
                            provider.upcomingClasses,
                            'upcoming',
                          ),
                          _buildClassesList(
                            provider.completedClasses,
                            'completed',
                          ),
                          _buildClassesList(provider.missedClasses, 'missed'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width < 400
                                    ? 24
                                    : 32,
                            vertical:
                                MediaQuery.of(context).size.width < 400
                                    ? 12
                                    : 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ScheduleClassesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Schedule a Class',
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width < 400
                                    ? 16
                                    : 18,
                            fontWeight: FontWeight.w600,
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

        // Parse class date and time for timing logic
        DateTime? classDateTime;
        try {
          final dateParts = date.split('/');
          if (dateParts.length == 3) {
            final month = int.parse(dateParts[0]);
            final day = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);

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

              classDateTime = DateTime(year, month, day, hour, minute);
            }
          }
        } catch (_) {}

        final now = DateTime.now();

        // Check if class is within the joinable window (5 minutes before to 10 minutes after)
        final canJoin =
            classDateTime != null &&
            now.isAfter(classDateTime.subtract(const Duration(minutes: 5))) &&
            now.isBefore(classDateTime.add(const Duration(minutes: 10)));

        // Determine button state for upcoming classes
        Widget? trailing;
        if (type == 'missed') {
          trailing = const Text(
            'Missed',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        } else if (type == 'completed') {
          trailing = const Text(
            'Completed',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          );
        } else if (type == 'upcoming') {
          // Show join and cancel buttons for all upcoming classes
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed:
                    canJoin && jitsiRoom.isNotEmpty
                        ? () async {
                          try {
                            // 1. Launch Jitsi meeting (mobile only)
                            final options = JitsiMeetConferenceOptions(
                              room: jitsiRoom,
                              userInfo: JitsiMeetUserInfo(
                                displayName: data['teacherName'] ?? 'Teacher',
                              ),
                              featureFlags: {
                                "welcomepage.enabled": false,
                                "startWithAudioMuted": false,
                                "startWithVideoMuted": false,
                              },
                            );
                            await JitsiMeet().join(options);
                            // 2. Mark as joined in Firestore
                            await FirebaseFirestore.instance
                                .collection('classes')
                                .doc(doc.id)
                                .update({
                                  'teacherJoined': true,
                                  'teacherJoinTime':
                                      FieldValue.serverTimestamp(),
                                });
                            // 3. Send notification to student
                            final studentId = data['studentId'] ?? '';
                            final teacherName = data['teacherName'] ?? '';
                            final studentName = data['studentName'] ?? '';
                            final classId = doc.id;
                            if (studentId.isNotEmpty) {
                              await NotificationService.sendJoinWaitingNotification(
                                receiverId: studentId,
                                senderName: teacherName,
                                senderRole: 'teacher',
                                classId: classId,
                              );
                            }
                            // 4. Refresh the provider to update UI
                            Provider.of<TeacherClassesMobileProvider>(
                              context,
                              listen: false,
                            ).loadClasses();
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
                  backgroundColor:
                      canJoin && jitsiRoom.isNotEmpty
                          ? appGreen
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                  foregroundColor:
                      canJoin
                          ? Colors.white
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width < 400 ? 8 : 12,
                    vertical: MediaQuery.of(context).size.width < 400 ? 6 : 8,
                  ),
                ),
                child: Text(
                  teacherJoined ? 'Rejoin' : 'Join',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width < 400 ? 6 : 8),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                ),
                label: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width < 400 ? 8 : 12,
                    vertical: MediaQuery.of(context).size.width < 400 ? 6 : 8,
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          title: Center(
                            child: const Text(
                              'Cancel Class',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel this class?',
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'No',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Yes'),
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
                        body:
                            'Your class scheduled on $classDate at $classTime has been cancelled by $teacherName.',
                        type: 'class_cancelled',
                        additionalData: {
                          'teacherName': teacherName,
                          'classDate': classDate,
                          'classTime': classTime,
                        },
                      );
                    }

                    // Refresh provider to update UI
                    Provider.of<TeacherClassesMobileProvider>(
                      context,
                      listen: false,
                    ).loadClasses();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class cancelled.')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        }

        return Card(
          elevation: 2,
          color: Theme.of(context).cardColor,
          shadowColor: Theme.of(context).shadowColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFe5faf3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 400 ? 8 : 6,
                  ),
                  child: Icon(
                    Icons.class_,
                    color: appGreen,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 400 ? 8 : 6,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaQuery.of(context).size.width < 400
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (trailing != null) trailing,
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Text(
                                  studentName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                              if (trailing != null)
                                Flexible(flex: 2, child: trailing),
                            ],
                          ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize:
                              MediaQuery.of(context).size.width < 400 ? 13 : 14,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize:
                              MediaQuery.of(context).size.width < 400 ? 13 : 14,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width < 400
                                    ? 13
                                    : 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
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
