import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/colors.dart';
import '../../../services/class_completion_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

// Helper function to detect mobile browsers
bool _isMobileBrowser() {
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
      throw Exception(
        'Unable to open Jitsi meeting. Please try again or copy the URL manually.',
      );
    }
  }
}

typedef QueryBuilder = Query Function(String userId);

class ClassesList extends StatelessWidget {
  final String type; // 'upcoming', 'completed', 'missed'
  final QueryBuilder? queryBuilder;
  const ClassesList({super.key, required this.type, this.queryBuilder});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Use custom queryBuilder if provided, otherwise fallback to old logic
    final Query classesQuery =
        queryBuilder != null
            ? queryBuilder!(userId!)
            : FirebaseFirestore.instance
                .collection('classes')
                .where('status', isEqualTo: type)
                .where('teacherId', isEqualTo: userId);

    return StreamBuilder<QuerySnapshot>(
      stream: classesQuery.snapshots(),
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
                  'No $type classes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        final classes = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final c = classes[index].data() as Map<String, dynamic>;
            final docId = classes[index].id;
            final subject = c['subject'] ?? '';
            final studentName = c['studentName'] ?? '';
            final date = c['date'] ?? '';
            final time = c['time'] ?? '';
            final jitsiRoom = c['jitsiRoom'] ?? '';
            final studentJoined = c['studentJoined'] ?? false;
            final teacherJoined = c['teacherJoined'] ?? false;

            // Parse classDateTime for missed logic
            DateTime? classDateTime;
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
            final now = DateTime.now();
            final isPast = classDateTime != null && classDateTime.isBefore(now);

            // Show join button for upcoming classes, otherwise show joined label if joined
            bool showJoin = type == 'upcoming' && !teacherJoined;
            bool showJoinedLabel = type == 'upcoming' && teacherJoined;

            // Completed logic for teacher:
            bool showCompleted = type == 'completed' && teacherJoined == true;
            // Missed logic for teacher:
            bool showMissed = type == 'missed' && teacherJoined == false;
            if (type == 'missed' && !showMissed) return const SizedBox.shrink();
            if (type == 'completed' && !showCompleted) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(0),
              child: Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
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
                            if (studentName.isNotEmpty)
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            else
                              FutureBuilder<DocumentSnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('students')
                                        .doc(c['studentId'])
                                        .get(),
                                builder: (context, studentSnapshot) {
                                  String fetchedName = 'Student';
                                  if (studentSnapshot.hasData &&
                                      studentSnapshot.data!.exists) {
                                    fetchedName =
                                        studentSnapshot.data!['fullName'] ??
                                        'Student';
                                  }
                                  return Text(
                                    fetchedName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                },
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
                            if (showJoin)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: OutlinedButton(
                                  onPressed:
                                      jitsiRoom.isNotEmpty
                                          ? () async {
                                            try {
                                              // Update teacher join status and set join time
                                              await FirebaseFirestore.instance
                                                  .collection('classes')
                                                  .doc(docId)
                                                  .update({
                                                    'teacherJoined': true,
                                                    'teacherJoinTime':
                                                        FieldValue.serverTimestamp(),
                                                  });

                                              // Launch Jitsi Meet
                                              final url =
                                                  'https://meet.jit.si/$jitsiRoom';

                                              await _launchJitsiMeeting(url);

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
                                        jitsiRoom.isNotEmpty
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Join'),
                                ),
                              ),
                            if (showJoinedLabel)
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
                            if (showCompleted)
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
                            if (showMissed)
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
              ),
            );
          },
        );
      },
    );
  }
}

// Helper function for time parsing
String _parseTimeTo24Hour(String time) {
  final timeRegExp = RegExp(r'(\d+):(\d+)\s*([AP]M)', caseSensitive: false);
  final match = timeRegExp.firstMatch(time.trim());
  if (match == null) return time;
  int hour = int.parse(match.group(1)!);
  int minute = int.parse(match.group(2)!);
  String period = match.group(3)!.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
