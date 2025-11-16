import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';

class AdminDashboardSummary extends StatelessWidget {
  const AdminDashboardSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget totalUsersCard = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, studentSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
          builder: (context, teacherSnapshot) {
            String total = '...';
            if (studentSnapshot.hasData && teacherSnapshot.hasData) {
              final studentCount = studentSnapshot.data!.docs.length;
              final teacherCount = teacherSnapshot.data!.docs.length;
              total = (studentCount + teacherCount).toString();
            }
            return _infoCard(
              context: context,
              assetPath: 'assets/logo/Totaluser.png',
              number: total,
              label: 'Total Users',
            );
          },
        );
      },
    );

    Widget activeClassCard = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }
        return _infoCard(
          context: context,
          assetPath: 'assets/logo/Activeclass.png',
          number: count,
          label: 'Active Classes',
        );
      },
    );

    Widget unassignedUsersCard = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
      builder: (context, teacherSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, studentSnapshot) {
            String total = '...';
            if (teacherSnapshot.hasData && studentSnapshot.hasData) {
              final teachers = teacherSnapshot.data!.docs;
              final students = studentSnapshot.data!.docs;
              final unassignedTeachers = teachers.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                final ids = data != null && data.containsKey('assignedStudentId') ? data['assignedStudentId'] : null;
                return ids == null || (ids is List && ids.isEmpty);
              }).length;
              final unassignedStudents = students.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                final tid = data != null && data.containsKey('assignedTeacherId') ? data['assignedTeacherId'] : null;
                return tid == null || (tid is String && tid.isEmpty);
              }).length;
              total = (unassignedTeachers + unassignedStudents).toString();
            }
            return _infoCard(
              context: context,
              assetPath: 'assets/logo/Unassigneduser.png',
              number: total,
              label: 'Unassigned users',
            );
          },
        );
      },
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 900;

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo/Frame.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Control center for everything',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            // You can add notification icon callback here if needed
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
                      child: activeClassCard,
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: totalUsersCard,
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: unassignedUsersCard,
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _infoCard(
                        context: context,
                        assetPath: 'assets/logo/Fees.png',
                        number: 'Paid/Unpaid',
                        label: 'Fees Status',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add user action here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '+ Add User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // You can add _userList(context) or other dashboard widgets here
                // const SizedBox(height: 24),
              ],
            );
          },
        ),
      ],
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
