import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../components/admin_sidebar.dart';
import '../../../constants/colors.dart';
import 'Teachers_details.dart';
import '../admin_home_screen.dart';
import '../../../services/notification_service.dart';
import 'assign_teachers_provider.dart';

class AssignTeachers extends StatelessWidget {
  final String studentUid;
  const AssignTeachers({super.key, required this.studentUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssignTeachersProvider(studentUid),
      child: Consumer<AssignTeachersProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWeb = screenWidth >= 900;
          double labelFontSize = isWeb ? 18 : 14;

          if (provider.loading) return const Center(child: CircularProgressIndicator());
          if (provider.unassignedTeachers.isEmpty) {
            if (provider.loadingAssigned) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.assignedTeachers.isEmpty) {
              return const Center(child: Text('No teachers found.'));
            }
            // Show assigned teachers with student count
            Widget assignedTeacherCard(
              Map<String, dynamic> teacher,
              double labelFontSize,
            ) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                color: Theme.of(context).cardColor,
                shadowColor: Theme.of(context).shadowColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(teacher['avatar'] ?? ''),
                    radius: 24,
                  ),
                  title: Text(
                    teacher['name'],
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text('Students: ${teacher['studentCount']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeachersDetails(
                          user: {
                            'uid': teacher['uid'],
                            'role': 'Teacher',
                            'avatar': teacher['avatar'],
                            ...teacher,
                          },
                          isUnassigned: false,
                          onAssign: studentUid.isNotEmpty
                              ? () async {
                                  await provider.assignTeacher(context, teacher);
                                }
                              : null,
                          isFinalAssignment: studentUid.isNotEmpty,
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            if (isWeb) {
              return _AdminShell(
                selectedIndex: 0,
                child: Column(
                  children: [
                    AppBar(
                      leading: BackButton(),
                      elevation: 0,
                      title: const Text(
                        'Assigned Teachers',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        itemCount: provider.assignedTeachers.length,
                        itemBuilder: (context, index) {
                          return assignedTeacherCard(
                            provider.assignedTeachers[index],
                            labelFontSize,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: AppBar(
                  title: const Text(
                    'Assigned Teachers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  elevation: 0,
                  leading: BackButton(),
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ListView.builder(
                    itemCount: provider.assignedTeachers.length,
                    itemBuilder: (context, index) {
                      return assignedTeacherCard(
                        provider.assignedTeachers[index],
                        labelFontSize,
                      );
                    },
                  ),
                ),
              );
            }
          }

          Widget teacherCard(
            Map<String, dynamic> teacher,
            bool assigned,
            double labelFontSize,
          ) {
            return GestureDetector(
              onTap: () async {
                final doc = await FirebaseFirestore.instance.collection('teachers').doc(teacher['uid']).get();
                final data = doc.data() ?? {};
                final userMap = {
                  'uid': teacher['uid'],
                  'role': 'Teacher',
                  'avatar': 'https://i.pravatar.cc/100?u=${teacher['uid']}',
                  ...data,
                };
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeachersDetails(
                      user: userMap,
                      isUnassigned: false,
                      onAssign: studentUid.isNotEmpty
                          ? () async {
                              await provider.assignTeacher(context, teacher);
                            }
                          : null,
                      isFinalAssignment: studentUid.isNotEmpty,
                    ),
                  ),
                );
                if (result == true) {
                  provider.assignedStatus[teacher['name']] = true;
                  provider.notifyListeners();
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                color: Theme.of(context).cardColor,
                shadowColor: Theme.of(context).shadowColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        teacher['name'],
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      assigned
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assigned',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: labelFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: appGreen,
                            ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isWeb) {
            return _AdminShell(
              selectedIndex: 0,
              child: Column(
                children: [
                  AppBar(
                    leading: BackButton(),
                    elevation: 0,
                    title: const Text(
                      'Assign Teachers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      itemCount: provider.unassignedTeachers.length,
                      itemBuilder: (context, index) {
                        final teacher = provider.unassignedTeachers[index];
                        final assigned = provider.assignedStatus[teacher['name']] ?? false;
                        return teacherCard(teacher, assigned, labelFontSize);
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text(
                  'Assign Teachers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                elevation: 0,
                leading: BackButton(),
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ListView.builder(
                  itemCount: provider.unassignedTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = provider.unassignedTeachers[index];
                    final assigned = provider.assignedStatus[teacher['name']] ?? false;
                    return teacherCard(teacher, assigned, labelFontSize);
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// Private shell widget for persistent sidebar in this file
class _AdminShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  const _AdminShell({required this.selectedIndex, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // AdminSidebar(selectedIndex: selectedIndex),
          Expanded(child: child),
        ],
      ),
    );
  }
}
