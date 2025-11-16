import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assign_students.dart';
import 'assign_teachers.dart';
import '../../../constants/colors.dart';
import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import '../admin_home_screen.dart';

class TeachersDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isUnassigned;
  final VoidCallback? onAssign;
  final bool isFinalAssignment;

  const TeachersDetails({
    super.key,
    required this.user,
    this.isUnassigned = false,
    this.onAssign,
    this.isFinalAssignment = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = user['role'] == 'Teacher';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 900;
        if (isWeb) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                AdminSidebar(selectedIndex: 0),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        leading: BackButton(),
                        elevation: 0,
                        title: Text(
                          isTeacher ? 'Teacher Profile' : 'Student Profile',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      ),
                      Expanded(child: _detailsContent(context, isWeb)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              leading: BackButton(),
              elevation: 0,
              title: Text(
                isTeacher ? 'Teacher Profile' : 'Student Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            body: _detailsContent(context, false),
          );
        }
      },
    );
  }

  Widget _detailsContent(BuildContext context, bool isWeb) {
    final isTeacher = user['role'] == 'Teacher';
    final String collection =
        isUnassigned
            ? (isTeacher ? 'unassigned_teachers' : 'unassigned_students')
            : (isTeacher ? 'teachers' : 'students');
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection(collection)
              .doc(user['uid'])
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No data found.'));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        final avatarUrl = user['avatar'] ?? '';
        final name = data['fullName'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phoneNumber'] ?? '';
        final country = data['country'] ?? '';
        final role = data['role'] ?? '';
        final degree = data['degree'] ?? '';
        final grade = data['grade'] ?? '';
        final favSubject = data['favouriteSubject'] ?? '';
        final assignedStudentId = data['assignedStudentId'];
        final hasAssignedStudents =
            assignedStudentId is List && assignedStudentId.isNotEmpty;
        final degreeProofUrl = data['degreeProofUrl'] ?? '';

        List<Widget> infoFields = [];
        void addField(String label, String? value) {
          if (value != null && value.isNotEmpty) {
            infoFields.add(_profileField(context, label, value));
            infoFields.add(const SizedBox(height: 14));
          }
        }

        addField('Full Name', name);
        addField('Email', email);
        addField('Phone Number', phone);
        addField('Country', country);
        if (isTeacher) {
          addField('Degree', degree);
          if (degreeProofUrl.isNotEmpty) {
            infoFields.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DegreePreviewScreen(imageUrl: degreeProofUrl),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Degree Proof',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: appGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.picture_as_pdf, color: appGreen),
                            SizedBox(width: 8),
                            Text(
                              'View Degree Proof',
                              style: TextStyle(fontSize: 14, color: appGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          addField('Grade', grade);
          addField('Favourite Subject', favSubject);
        }
        addField('Role', role);

        if (isWeb) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: Card(
                      color: Theme.of(context).cardColor,
                      shadowColor: Theme.of(context).shadowColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(role, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 10),
                            if (isTeacher &&
                                isFinalAssignment &&
                                onAssign != null) ...[
                              ElevatedButton(
                                onPressed: () async {
                                  onAssign!();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  );
                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );
                                  Navigator.of(context).pop();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AdminHomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Assign',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (isTeacher &&
                                !isFinalAssignment &&
                                !hasAssignedStudents) ...[
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AssignStudents(
                                            teacherUid: user['uid'],
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Assign To',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (!isTeacher && onAssign != null) ...[
                              ElevatedButton(
                                onPressed: () {
                                  onAssign!();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  isFinalAssignment ? 'Assign' : 'Assign To',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: Card(
                      color: Theme.of(context).cardColor,
                      shadowColor: Theme.of(context).shadowColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: infoFields,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    shadowColor: Theme.of(context).shadowColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...infoFields,
                          const SizedBox(height: 20),
                          if (isTeacher &&
                              isFinalAssignment &&
                              onAssign != null) ...[
                            ElevatedButton(
                              onPressed: () async {
                                onAssign!();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                );
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                Navigator.of(context).pop();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AdminHomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Assign',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (isTeacher &&
                              !isFinalAssignment &&
                              !hasAssignedStudents) ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AssignStudents(
                                          teacherUid: user['uid'],
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Assign To',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (!isTeacher && onAssign != null) ...[
                            ElevatedButton(
                              onPressed: () {
                                onAssign!();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                isFinalAssignment ? 'Assign' : 'Assign To',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _profileField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: appGrey),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: appGrey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

class DegreePreviewScreen extends StatelessWidget {
  final String imageUrl;

  const DegreePreviewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Degree Preview')),
      body: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
    );
  }
}
