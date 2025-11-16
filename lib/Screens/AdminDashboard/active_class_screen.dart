import 'package:al_mehdi_online_school/Screens/AdminDashboard/admin_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/notifications.dart';
import 'package:provider/provider.dart';

import 'active_class_provider.dart';
import 'notification_screen.dart';
import 'notifications_provider.dart';

class ActiveClassScreen extends StatelessWidget {
  const ActiveClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider()..initialize(),
      child: ChangeNotifierProvider(
        create: (_) => ActiveClassProvider(),
        child: Consumer<ActiveClassProvider>(
          builder: (context, provider, _) {
            Widget activeClassContent = Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.activeClasses.isEmpty)
                    Center(
                      child: Text(
                        'No active classes',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.activeClasses.length,
                        itemBuilder: (context, index) {
                          final data = provider.activeClasses[index];
                          return Card(
                            color: Theme.of(context).cardColor,
                            margin: EdgeInsets.only(bottom: 20.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe5faf3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.class_,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Student: \t\t${data['studentName'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Teacher: ${data['teacherName'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.0,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Time: ${data['time'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 13.0,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      ),
                    ),
                ],
              ),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Active Classes',
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
                                      builder: (context) => Notifications(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(child: activeClassContent),
                      ],
                    ),
                  );
                }
                return _mobileLayout(context, provider);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, ActiveClassProvider provider) {
    return Scaffold(
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
          'Active Classes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.loading)
              const Center(child: CircularProgressIndicator())
            else if (provider.activeClasses.isEmpty)
              Center(
                child: Text(
                  'No active classes',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.activeClasses.length,
                  itemBuilder: (context, index) {
                    final data = provider.activeClasses[index];
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFe5faf3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.class_,
                                color: Colors.green,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student: \t\t${data['studentName'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Teacher: ${data['teacherName'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.0,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Time: ${data['time'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14.0,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
