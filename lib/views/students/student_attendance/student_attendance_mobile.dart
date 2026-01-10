import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../../../../constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentAttendanceMobileView extends StatelessWidget {
  const StudentAttendanceMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('classes')
                  .where(
                    'studentId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No attendance data available');
            }
            final docs = snapshot.data!.docs;
            final y = docs.length;
            final x =
                docs
                    .where(
                      (doc) =>
                          (doc.data()
                              as Map<String, dynamic>)['attendanceStatus'] ==
                          'present',
                    )
                    .length;
            final missedForChart = y - x;
            final missedForCard =
                docs
                    .where(
                      (doc) =>
                          (doc.data()
                              as Map<String, dynamic>)['attendanceStatus'] ==
                          'absent',
                    )
                    .length;
            final percentage = y == 0 ? 0 : (x / y) * 100;
            final dataMapRaw = {
              "Attended": x.toDouble(),
              "Missed": missedForChart.toDouble(),
            };
            final dataMap = Map.fromEntries(
              dataMapRaw.entries.where((e) => e.value > 0),
            );
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PieChart(
                    dataMap: dataMap.isNotEmpty ? dataMap : {"No Data": 1.0},
                    chartRadius: MediaQuery.of(context).size.width / 3,
                    animationDuration: const Duration(milliseconds: 800),
                    chartType: ChartType.ring,
                    ringStrokeWidth: 20,
                    baseChartColor: Colors.transparent,
                    colorList: [appGreen, Color(0xFFFFA07A)],
                    initialAngleInDegree: 90,
                    centerText: "${percentage.toStringAsFixed(0)}%",
                    centerTextStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appGreen,
                      backgroundColor: Colors.transparent,
                    ),
                    legendOptions: const LegendOptions(showLegends: false),
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValues: false,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    percentage == 100
                        ? "Excellent!"
                        : percentage >= 75
                        ? "Good!"
                        : "Needs Improvement",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AttendanceStatCard(label: "Total Classes", value: y),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AttendanceStatCard(
                      label: "Classes Attended",
                      value: x,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AttendanceStatCard(
                      label: "Classes Missed",
                      value: missedForCard,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AttendanceStatCard extends StatelessWidget {
  final String label;
  final int value;

  const AttendanceStatCard({
    super.key,
    required this.label,
    required this.value,
  });

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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
