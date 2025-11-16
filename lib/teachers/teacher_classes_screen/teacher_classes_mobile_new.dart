import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'teacher_classes_mobile_provider.dart';
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
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
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
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
