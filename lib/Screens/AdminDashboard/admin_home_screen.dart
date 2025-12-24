import 'package:al_mehdi_online_school/Screens/AdminDashboard/active_class_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/fees_status_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/notifications.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/admin_mian_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/profile_screen_provider.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/sidebar%20and%20bottom%20Tabs%20Screens/schedule_class.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/total_users_screen.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/Unassigned%20Users%20Screens/unassigned_users_screen.dart';
import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_provider.dart';
import 'package:provider/provider.dart';
import 'notifications_provider.dart';
import '../../providers/admin_main_screen_provider.dart';
import 'sidebar and bottom Tabs Screens/attendance_screen.dart';
import 'sidebar and bottom Tabs Screens/chat_screen.dart';
import 'sidebar and bottom Tabs Screens/profile_screen.dart';
import 'sidebar and bottom Tabs Screens/settings_screen.dart';
import 'package:al_mehdi_online_school/services/notification_service.dart';
import 'package:al_mehdi_online_school/services/session_helper.dart';
import 'sidebar and bottom Tabs Screens/admin_settings_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAdminNotifications();
  }

  Future<void> _initializeAdminNotifications() async {
    try {
      // Initialize notification service
      await NotificationService.initialize();
      
      // Get admin email from session
      final adminEmail = await getAdminEmail();
      if (adminEmail != null) {
        // Find admin document by email
        final adminQuery = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: adminEmail)
            .limit(1)
            .get();
        
        if (adminQuery.docs.isNotEmpty) {
          final adminId = adminQuery.docs.first.id;
          await NotificationService.saveTokenToFirestore(adminId);
          print('FCM token saved for admin: $adminId');
        }
      }
    } catch (e) {
      print('Error initializing admin notifications: $e');
    }
  }

  List<Widget> get _screens => [
    AdminHomeContent(), // 0: Home
    const ScheduleClass(), // 1: Classes
    AttendanceScreen(), // 2: Attendance
    ChatScreen(), // 3: Chat
    SettingsScreen(), // 4: Settings
    ChangeNotifierProvider<ProfileScreenProvider>(
      create: (_) => ProfileScreenProvider(),
      child: ProfileScreen(),
    ), // 5: Profile
    // ...other screens if needed
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminMainScreenProvider, AdminHomeProvider>(
      builder: (context, mainProvider, homeProvider, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWeb = screenWidth >= 900;
        int selectedIndex = mainProvider.selectedIndex;
        // If Home is selected, but a sub-screens is set, show the sub-screen
        Widget mainContent;
        if (selectedIndex == 0 && homeProvider.mainContentScreen != null) {
          switch (homeProvider.mainContentScreen) {
            case 'activeClasses':
              mainContent = ActiveClassScreen();
              break;
            case 'totalUsers':
              mainContent = TotalUsersScreen();
              break;
            case 'unassignedUsers':
              mainContent = UnassignedUsersScreen();
              break;
            case 'feesStatus':
              mainContent = FeesStatusScreen();
              break;
            default:
              mainContent = AdminHomeContent();
          }
        } else if (selectedIndex == 0) {
          mainContent = AdminHomeContent();
        } else {
          mainContent = _screens[selectedIndex];
        }
        if (isWeb) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                AdminSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {
                    if (index == 0) {
                      homeProvider.showDashboard();
                      mainProvider.setSelectedIndex(0);
                    } else {
                      mainProvider.setSelectedIndex(index);
                    }
                  },
                ),
                Expanded(child: mainContent),
              ],
            ),
          );
        } else {
          // Always use AdminMainScreen for mobile to get bottom navigation and correct tab switching
          return AdminMainScreen();
        }
      },
    );
  }
}

class AdminHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider()..initialize(),
      child: Consumer<AdminHomeProvider>(
        builder: (context, provider, _) {
          // final screenWidth = MediaQuery.of(context).size.width; // no longer needed here
          // final isWeb = screenWidth >= 900; // not used

          Widget totalUsersCard = _infoCard(
            context: context,
            assetPath: 'assets/logo/Totaluser.png',
            number: provider.loading ? '...' : provider.totalUsers.toString(),
            label: 'Total Users',
          );

          Widget activeClassCard = _infoCard(
            context: context,
            assetPath: 'assets/logo/Activeclass.png',
            number:
                provider.loading ? '...' : provider.activeClasses.toString(),
            label: 'Active Classes',
          );

          Widget unassignedUsersCard = _infoCard(
            context: context,
            assetPath: 'assets/logo/Unassigneduser.png',
            number:
                provider.loading ? '...' : provider.unassignedUsers.toString(),
            label: 'Unassigned users',
          );

          // Only apply padding for dashboard (main home screen)
          if (provider.mainContentScreen == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: _buildDashboardContent(
                context,
                provider,
                totalUsersCard,
                activeClassCard,
                unassignedUsersCard,
              ),
            );
          } else {
            switch (provider.mainContentScreen) {
              case 'activeClasses':
                return ActiveClassScreen();
              case 'totalUsers':
                return TotalUsersScreen();
              case 'unassignedUsers':
                return UnassignedUsersScreen();
              case 'feesStatus':
                return FeesStatusScreen();
              default:
                return SizedBox.shrink();
            }
          }
        },
      ),
    );
  }
}

class MobileVersion extends StatelessWidget {
  const MobileVersion({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider()..initialize(),
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          Widget activeClassCard = StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('classes')
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
            builder: (context, snapshot) {
              String count = '...';
              if (snapshot.hasData) {
                count = snapshot.data!.docs.length.toString();
              }
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActiveClassScreen(),
                    ),
                  );
                },
                child: _infoCard(
                  context: context,
                  assetPath: 'assets/logo/Activeclass.png',
                  number: count,
                  label: 'Active Classes',
                ),
              );
            },
          );
          Widget totalUsersCard = StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('students').snapshots(),
            builder: (context, studentSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('teachers')
                        .snapshots(),
                builder: (context, teacherSnapshot) {
                  String total = '...';
                  if (studentSnapshot.hasData && teacherSnapshot.hasData) {
                    final studentCount = studentSnapshot.data!.docs.length;
                    final teacherCount = teacherSnapshot.data!.docs.length;
                    total = (studentCount + teacherCount).toString();
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TotalUsersScreen(),
                        ),
                      );
                    },
                    child: _infoCard(
                      context: context,
                      assetPath: 'assets/logo/Totaluser.png',
                      number: total,
                      label: 'Total Users',
                    ),
                  );
                },
              );
            },
          );
          Widget unassignedUsersCard = StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('teachers').snapshots(),
            builder: (context, teacherSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('students')
                        .snapshots(),
                builder: (context, studentSnapshot) {
                  String total = '...';
                  if (teacherSnapshot.hasData && studentSnapshot.hasData) {
                    final teachers = teacherSnapshot.data!.docs;
                    final students = studentSnapshot.data!.docs;
                    final unassignedTeachers =
                        teachers.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          final ids =
                              data != null &&
                                      data.containsKey('assignedStudentId')
                                  ? data['assignedStudentId']
                                  : null;
                          return ids == null || (ids is List && ids.isEmpty);
                        }).length;
                    final unassignedStudents =
                        students.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          final tid =
                              data != null &&
                                      data.containsKey('assignedTeacherId')
                                  ? data['assignedTeacherId']
                                  : null;
                          return tid == null || (tid is String && tid.isEmpty);
                        }).length;
                    total =
                        (unassignedTeachers + unassignedStudents).toString();
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnassignedUsersScreen(),
                        ),
                      );
                    },
                    child: _infoCard(
                      context: context,
                      assetPath: 'assets/logo/Unassigneduser.png',
                      number: total,
                      label: 'Unassigned users',
                    ),
                  );
                },
              );
            },
          );
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Image.asset('assets/logo/Frame.png', width: 25, height: 25),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Control center for everything',
                          style: TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              elevation: 0,
              actions: [
                AdminNotificationIcon(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Notifications(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FutureBuilder<Map<String, dynamic>?>(
                  future: FirebaseFirestore.instance
                      .collection('admin')
                      .limit(1)
                      .get()
                      .then((q) => q.docs.isNotEmpty ? q.docs.first.data() : null),
                  builder: (context, snap) {
                    final photoUrl = snap.data?['profilePictureUrl'] as String?;
                    return CircleAvatar(
                      radius: 16,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    AdminSettingsProvider().showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      InkWell(
                        hoverColor: Colors.transparent,
                        onTap: () => _goToActiveClass(context),
                        child: SizedBox(
                          width: (screenWidth - 48) / 2,
                          child: activeClassCard,
                        ),
                      ),
                      InkWell(
                        hoverColor: Colors.transparent,
                        onTap: () => _goToTotalUsers(context),
                        child: SizedBox(
                          width: (screenWidth - 48) / 2,
                          child: totalUsersCard,
                        ),
                      ),
                      InkWell(
                        hoverColor: Colors.transparent,
                        onTap: () => _goToUnassignedUsers(context),
                        child: SizedBox(
                          width: (screenWidth - 48) / 2,
                          child: unassignedUsersCard,
                        ),
                      ),
                      InkWell(
                        hoverColor: Colors.transparent,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FeesStatusScreen(),
                              ),
                            ),
                        child: SizedBox(
                          width: (screenWidth - 48) / 2,
                          child: _infoCard(
                            context: context,
                            assetPath: 'assets/logo/Fees.png',
                            number: 'Paid/Unpaid',
                            label: 'Fees Status',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Schedule Class Button (full width)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _goToScheduleClass(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Schedule Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
            // bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0),
          );
        },
      ),
    );
  }
}

Widget _infoCard({
  required BuildContext context,
  required String assetPath,
  required String number,
  required String label,
  String? extraLabel,
}) {
  return Card(
    color: Theme.of(context).cardColor,
    shadowColor: Theme.of(context).shadowColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 50, height: 50, fit: BoxFit.contain),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (extraLabel != null) ...[
            const SizedBox(height: 4),
            Text(extraLabel, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

void _goToActiveClass(BuildContext context) {
  Provider.of<AdminHomeProvider>(
    context,
    listen: false,
  ).showMainContent('activeClasses');
}

void _goToTotalUsers(BuildContext context) {
  Provider.of<AdminHomeProvider>(
    context,
    listen: false,
  ).showMainContent('totalUsers');
}

void _goToUnassignedUsers(BuildContext context) {
  Provider.of<AdminHomeProvider>(
    context,
    listen: false,
  ).showMainContent('unassignedUsers');
}

void _goToFeesStatus(BuildContext context) {
  Provider.of<AdminHomeProvider>(
    context,
    listen: false,
  ).showMainContent('feesStatus');
}

void _goToScheduleClass(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isWeb = screenWidth >= 900;
  if (isWeb) {
    Provider.of<AdminMainScreenProvider>(
      context,
      listen: false,
    ).setSelectedIndex(1); // 1 = Classes tab
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleClass()),
    );
  }
}

Widget _buildDashboardContent(
  BuildContext context,
  AdminHomeProvider provider,
  Widget totalUsersCard,
  Widget activeClassCard,
  Widget unassignedUsersCard,
) {
  return ListView(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logo/Frame.png', width: 36, height: 36),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  Text(
                    'Control center for everything',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              AdminNotificationIcon(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Notifications()),
                  );
                },
              ),
              const SizedBox(width: 8),
              FutureBuilder<Map<String, dynamic>?>(
                future: FirebaseFirestore.instance
                    .collection('admin')
                    .limit(1)
                    .get()
                    .then((q) => q.docs.isNotEmpty ? q.docs.first.data() : null),
                builder: (context, snap) {
                  final photoUrl = snap.data?['profilePictureUrl'] as String?;
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  );
                },
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  AdminSettingsProvider().showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 16.0;
          final totalSpacing = spacing * 3;
          final cardWidth = (constraints.maxWidth - totalSpacing) / 4;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _goToActiveClass(context),
                      child: activeClassCard,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _goToTotalUsers(context),
                      child: totalUsersCard,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _goToUnassignedUsers(context),
                      child: unassignedUsersCard,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _goToFeesStatus(context),
                      child: _infoCard(
                        context: context,
                        assetPath: 'assets/logo/Fees.png',
                        number: 'Paid/Unpaid',
                        label: 'Fees Status',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      // Schedule Class Button
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _goToScheduleClass(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: appGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Schedule Class',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
