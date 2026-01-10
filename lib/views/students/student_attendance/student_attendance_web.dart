import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/student_attendance_web_provider.dart';
import '../../../services/notification_service.dart';
import '../student_notifications/student_notifications.dart';

class StudentAttendanceWebView extends StatelessWidget {
  const StudentAttendanceWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentAttendanceWebProvider()..fetchAttendance(),
      child: Consumer<StudentAttendanceWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and notification icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Attendance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  NotificationService.getNotificationsStream(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount =
                                      snapshot.data!.docs
                                          .where(
                                            (doc) => !(doc['read'] ?? false),
                                          )
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
                                            builder:
                                                (context) =>
                                                    StudentNotificationScreen(),
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
                          ],
                        ),
                      ),
                      const Divider(),
                      // Overall Attendance
                      Expanded(
                        child: Center(
                          child:
                              provider.loading
                                  ? const CircularProgressIndicator()
                                  : provider.error.isNotEmpty
                                  ? Text('Error: ${provider.error}')
                                  : LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 900) {
                                        // Small screen: stack vertically
                                        return SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 32.0,
                                                      horizontal: 24,
                                                    ),
                                                child: PieChartSection(
                                                  x: provider.attended,
                                                  y: provider.total,
                                                  missedForChart:
                                                      provider.missedForChart,
                                                  percentage:
                                                      provider.percentage,
                                                  dataMap: provider.dataMap,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 24,
                                                    ),
                                                child: StatCardsSection(
                                                  y: provider.total,
                                                  x: provider.attended,
                                                  missedForCard:
                                                      provider.missedForCard,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        // Large screen: side by side
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 50.0,
                                                    horizontal: 100,
                                                  ),
                                              child: PieChartSection(
                                                x: provider.attended,
                                                y: provider.total,
                                                missedForChart:
                                                    provider.missedForChart,
                                                percentage: provider.percentage,
                                                dataMap: provider.dataMap,
                                              ),
                                            ),
                                            const SizedBox(width: 48),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 40,
                                                    ),
                                                child: StatCardsSection(
                                                  y: provider.total,
                                                  x: provider.attended,
                                                  missedForCard:
                                                      provider.missedForCard,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Color valueColor;
    if (label.toLowerCase().contains('attended')) {
      valueColor = appGreen;
    } else if (label.toLowerCase().contains('missed')) {
      valueColor = const Color(0xFFFFA07A);
    } else {
      valueColor = Colors.blueGrey;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartSection extends StatelessWidget {
  final int x, y, missedForChart;
  final double percentage;
  final Map<String, double> dataMap;
  const PieChartSection({
    super.key,
    required this.x,
    required this.y,
    required this.missedForChart,
    required this.percentage,
    required this.dataMap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40),
        PieChart(
          dataMap: dataMap.isNotEmpty ? dataMap : {"No Data": 1.0},
          chartRadius: 200,
          animationDuration: const Duration(milliseconds: 800),
          chartType: ChartType.ring,
          ringStrokeWidth: 35,
          baseChartColor: Colors.transparent,
          colorList: [appGreen, Color(0xFFFFA07A)],
          initialAngleInDegree: 90,
          centerText: "${percentage.toStringAsFixed(0)}%",
          centerTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appGreen,
            backgroundColor: Colors.transparent,
          ),
          legendOptions: const LegendOptions(showLegends: false),
          chartValuesOptions: const ChartValuesOptions(showChartValues: false),
        ),
        const SizedBox(height: 20),
        Text(
          percentage == 100
              ? "Excellent!"
              : percentage >= 75
              ? "Good!"
              : "Needs Improvement",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}

class StatCardsSection extends StatelessWidget {
  final int y, x, missedForCard;
  const StatCardsSection({
    super.key,
    required this.y,
    required this.x,
    required this.missedForCard,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoTile(label: "Total Classes", value: "$y"),
        const SizedBox(height: 12),
        InfoTile(label: "Classes Attended", value: "$x"),
        const SizedBox(height: 12),
        InfoTile(label: "Classes Missed", value: "$missedForCard"),
      ],
    );
  }
}
