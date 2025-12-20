import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import 'Teachers_details.dart';
import 'assign_students_provider.dart';

class AssignStudents extends StatelessWidget {
  final String teacherUid;
  const AssignStudents({super.key, required this.teacherUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssignStudentsProvider(teacherUid),
      child: Consumer<AssignStudentsProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWeb = screenWidth >= 900;
          double labelFontSize = isWeb ? 18 : 14;

          if (provider.loading)
            return const Center(child: CircularProgressIndicator());
          if (provider.unassignedStudents.isEmpty) {
            return const Center(child: Text('No unassigned students'));
          }

          Widget studentCard(
            Map<String, dynamic> student,
            bool assigned,
            double labelFontSize,
          ) {
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TeachersDetails(
                          user: {...student, 'role': 'Student'},
                          isUnassigned: true,
                          onAssign:
                              teacherUid.isNotEmpty
                                  ? () =>
                                      provider.assignStudent(context, student)
                                  : null,
                          isFinalAssignment: teacherUid.isNotEmpty,
                        ),
                  ),
                );
                if (result == true) {
                  provider.assignedStatus[student['name']] = true;
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        student['name'],
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
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Row(
                children: [
                  // AdminSidebar(selectedIndex: 0),
                  Expanded(
                    child: Column(
                      children: [
                        AppBar(
                          leading: BackButton(),
                          elevation: 0,
                          title: const Text(
                            'Assign Students',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            itemCount: provider.unassignedStudents.length,
                            itemBuilder: (context, index) {
                              final student =
                                  provider.unassignedStudents[index];
                              final assigned =
                                  provider.assignedStatus[student['name']] ??
                                  false;
                              return studentCard(
                                student,
                                assigned,
                                labelFontSize,
                              );
                            },
                          ),
                        ),
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
                title: const Text(
                  'Assign Students',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                elevation: 0,
                leading: BackButton(),
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ListView.builder(
                  itemCount: provider.unassignedStudents.length,
                  itemBuilder: (context, index) {
                    final student = provider.unassignedStudents[index];
                    final assigned =
                        provider.assignedStatus[student['name']] ?? false;
                    return studentCard(student, assigned, labelFontSize);
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
