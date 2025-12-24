import 'package:al_mehdi_online_school/Screens/AdminDashboard/admin_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifications.dart';
import '../notifications_provider.dart';
import 'Teachers_details.dart';
import 'assign_students.dart';
import 'assign_teachers.dart';
import 'unassigned_users_provider.dart';

class UnassignedUsersScreen extends StatelessWidget {
  const UnassignedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(),
      child: _UnassignedUsersScreenContent(),
    );
  }
}

class _UnassignedUsersScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final double fontSize = isWeb ? 16 : 15;
    final double padding = isWeb ? 24 : 16;
    final double avatarSize = isWeb ? 48 : 40;
    final double cardMargin = isWeb ? 16 : 12;

    if (isWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Unassigned Users',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const Spacer(),
                              AdminNotificationIcon(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const Notifications(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: UnassignedTeachersList(
                            fontSize: fontSize,
                            padding: padding,
                            avatarSize: avatarSize,
                            cardMargin: cardMargin,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _mobileLayout(
            context,
            fontSize,
            padding,
            avatarSize,
            cardMargin,
          );
        },
      );
    }
    return _mobileLayout(context, fontSize, padding, avatarSize, cardMargin);
  }

  Widget _mobileLayout(
    BuildContext context,
    double fontSize,
    double padding,
    double avatarSize,
    double cardMargin,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminHomeScreen()),
              );
            },
          ),
          title: const Text(
            'Unassigned Users',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: UnassignedTeachersList(
          fontSize: fontSize,
          padding: padding,
          avatarSize: avatarSize,
          cardMargin: cardMargin,
        ),
      ),
    );
  }
}

class UnassignedTeachersList extends StatelessWidget {
  final double fontSize;
  final double padding;
  final double avatarSize;
  final double cardMargin;
  const UnassignedTeachersList({
    super.key,
    required this.fontSize,
    required this.padding,
    required this.avatarSize,
    required this.cardMargin,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UnassignedUsersProvider(),
      child: Consumer<UnassignedUsersProvider>(
        builder: (context, provider, _) {
          if (provider.loading)
            return const Center(child: CircularProgressIndicator());
          if (provider.unassignedTeachers.isEmpty &&
              provider.unassignedStudents.isEmpty) {
            return const Center(child: Text('No unassigned users'));
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
            child: ListView(
              children: [
                if (provider.unassignedTeachers.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Teachers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ...provider.unassignedTeachers.map(
                    (user) => _userCard(
                      context,
                      user,
                      avatarSize,
                      fontSize,
                      cardMargin,
                    ),
                  ),
                ],
                if (provider.unassignedStudents.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      ' Students',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ...provider.unassignedStudents.map(
                    (user) => _userCard(
                      context,
                      user,
                      avatarSize,
                      fontSize,
                      cardMargin,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _userCard(
    BuildContext context,
    Map<String, dynamic> user,
    double avatarSize,
    double fontSize,
    double cardMargin,
  ) {
    final isTeacher = user['role'] == 'Teacher';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TeachersDetails(
                  user: user,
                  isUnassigned: !isTeacher,
                  onAssign:
                      isTeacher
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AssignStudents(teacherUid: user['uid']),
                              ),
                            );
                          }
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AssignTeachers(studentUid: user['uid']),
                              ),
                            );
                          },
                ),
          ),
        );
      },
      child: Card(
        color: Theme.of(context).cardColor,
        shadowColor: Theme.of(context).shadowColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundImage: NetworkImage(user['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isTeacher ? Colors.blue[50] : Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['role'] ?? '',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: isTeacher ? Colors.blue : Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
