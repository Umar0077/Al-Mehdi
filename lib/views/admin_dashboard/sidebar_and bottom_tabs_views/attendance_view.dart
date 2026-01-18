import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/notifications_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin/attendance_content_provider.dart';
import '../../../providers/unassigned_user/notifications_provider.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 900;
    if (isWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AttendanceContent(), // Remove sidebar here
      );
    } else {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              'Attendance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AttendanceContent(),
        ),
        // bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 2),
      );
    }
  }
}

class AttendanceContent extends StatelessWidget {
  const AttendanceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(),
      child: ChangeNotifierProvider(
        create: (_) => AttendanceContentProvider(),
        child: Consumer<AttendanceContentProvider>(
          builder: (context, provider, _) {
            final isWeb = MediaQuery.of(context).size.width >= 900;
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (isWeb) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Attendance Report',
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
                                builder: (context) => NotificationView(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildFilterRow(context, provider),
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AdminAttendanceReport(
                        selectedTeacherId: provider.selectedTeacherId,
                        selectedStudentId: provider.selectedStudentId,
                        searchQuery: provider.searchQuery,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Responsive mobile layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed filter section
                  Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                context,
                                provider,
                                "Teacher",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                context,
                                provider,
                                "Student",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: provider.searchController,
                          cursorColor: appGreen,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.0,
                              ),
                            ),
                          ),
                          onChanged: provider.setSearchQuery,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                "Attendance Report",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "${_getMonthName(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year} · ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Scrollable attendance list
                  Expanded(
                    child: AdminAttendanceReport(
                      selectedTeacherId: provider.selectedTeacherId,
                      selectedStudentId: provider.selectedStudentId,
                      searchQuery: provider.searchQuery,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    AttendanceContentProvider provider,
    String hint,
  ) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    if (hint == "Teacher") {
      List<Map<String, dynamic>> filteredTeachers = List.from(
        provider.teachers,
      );
      if (provider.selectedStudentId != null) {
        final student = provider.students.firstWhere(
          (s) => s['id'] == provider.selectedStudentId,
          orElse: () => {},
        );
        final assignedTeacherId = student['assignedTeacherId'];
        filteredTeachers =
            provider.teachers
                .where((t) => t['id'] == assignedTeacherId)
                .toList();
      }
      if (provider.searchQuery.isNotEmpty) {
        filteredTeachers =
            filteredTeachers
                .where(
                  (t) => (t['name'] as String).toLowerCase().contains(
                    provider.searchQuery.toLowerCase(),
                  ),
                )
                .toList();
      }
      List<DropdownMenuItem<String>> dropdownItems = [];
      dropdownItems.add(
        const DropdownMenuItem<String>(
          value: 'all_teachers',
          child: Text('All Teachers'),
        ),
      );
      for (var teacher in filteredTeachers) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: teacher['id'] as String,
            child: Text(teacher['name'] as String),
          ),
        );
      }
      String? currentValue = provider.selectedTeacherId;
      if (currentValue != null &&
          !dropdownItems.any((item) => item.value == currentValue)) {
        currentValue = 'all_teachers';
      }
      return Flexible(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              focusColor: Colors.transparent,
              dropdownColor: dropdownColor,
              isExpanded: true,
              hint: Text(hint),
              value: currentValue ?? 'all_teachers',
              items: dropdownItems,
              onChanged: (String? newValue) {
                provider.setSelectedTeacherId(
                  newValue == 'all_teachers' ? null : newValue,
                );
                if (provider.selectedStudentId != null) {
                  final student = provider.students.firstWhere(
                    (s) => s['id'] == provider.selectedStudentId,
                    orElse: () => {},
                  );
                  if (student['assignedTeacherId'] != newValue) {
                    provider.setSelectedStudentId(null);
                  }
                }
              },
              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
            ),
          ),
        ),
      );
    } else if (hint == "Student") {
      List<Map<String, dynamic>> filteredStudents = List.from(
        provider.students,
      );
      if (provider.selectedTeacherId != null) {
        filteredStudents =
            provider.students
                .where(
                  (s) => s['assignedTeacherId'] == provider.selectedTeacherId,
                )
                .toList();
      }
      if (provider.searchQuery.isNotEmpty) {
        filteredStudents =
            filteredStudents
                .where(
                  (s) => (s['name'] as String).toLowerCase().contains(
                    provider.searchQuery.toLowerCase(),
                  ),
                )
                .toList();
      }
      if (filteredStudents.isEmpty) {
        return Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              provider.selectedTeacherId != null
                  ? 'No students assigned'
                  : 'No students available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        );
      }
      List<DropdownMenuItem<String>> dropdownItems = [];
      dropdownItems.add(
        const DropdownMenuItem<String>(
          value: 'all_students',
          child: Text('All Students'),
        ),
      );
      for (var student in filteredStudents) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: student['id'] as String,
            child: Text(student['name'] as String),
          ),
        );
      }
      String? currentValue = provider.selectedStudentId;
      if (currentValue != null &&
          !dropdownItems.any((item) => item.value == currentValue)) {
        currentValue = 'all_students';
      }
      return Flexible(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              focusColor: Colors.transparent,
              dropdownColor: dropdownColor,
              isExpanded: true,
              hint: Text(hint),
              value: currentValue ?? 'all_students',
              items: dropdownItems,
              onChanged: (String? newValue) {
                provider.setSelectedStudentId(
                  newValue == 'all_students' ? null : newValue,
                );
                if (provider.selectedTeacherId != null) {
                  final student = provider.students.firstWhere(
                    (s) => s['id'] == newValue,
                    orElse: () => {},
                  );
                  if (student['assignedTeacherId'] !=
                      provider.selectedTeacherId) {
                    provider.setSelectedTeacherId(null);
                  }
                }
              },
              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilterRow(
    BuildContext context,
    AttendanceContentProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          _buildDropdown(context, provider, "Teacher"),
          const SizedBox(width: 20),
          _buildDropdown(context, provider, "Student"),
          const SizedBox(width: 20),
          Flexible(
            flex: 2,
            child: TextField(
              controller: provider.searchController,
              cursorColor: appGreen,
              decoration: InputDecoration(
                hintText: 'Search teacher or student...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                ),
                suffixIcon:
                    provider.searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: appGreen),
                          onPressed: () {
                            provider.searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                        : null,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final formattedDate = "${_getMonthName(now.month)} ${now.day}, ${now.year}";
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Attendance Report",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "$formattedDate · $formattedTime",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month];
  }
}

class AdminAttendanceReport extends StatelessWidget {
  final String? selectedTeacherId;
  final String? selectedStudentId;
  final String searchQuery;
  const AdminAttendanceReport({
    super.key,
    required this.selectedTeacherId,
    required this.selectedStudentId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('classes')
              .where('status', isEqualTo: 'completed')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No attendance data available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Attendance records will appear here once classes are completed',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter classes based on completed status and attendance data
        final classes =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Must be a completed class with attendance data
              if (data['status'] != 'completed') return false;
              if (!data.containsKey('attendanceStatus')) return false;

              // Apply teacher filter
              if (selectedTeacherId != null &&
                  data['teacherId'] != selectedTeacherId) {
                return false;
              }

              // Apply student filter - check both studentId and studentName
              if (selectedStudentId != null) {
                final studentId = data['studentId'];
                final studentName = data['studentName'];
                if (studentId != selectedStudentId &&
                    studentName != selectedStudentId) {
                  return false;
                }
              }

              return true;
            }).toList();

        if (classes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check back later',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final data = classes[index].data() as Map<String, dynamic>;
            final teacherId = data['teacherId'] ?? '';
            final studentId = data['studentId'] ?? '';
            final studentName = data['studentName'] ?? '';
            final date = data['date'] ?? '';
            final time = data['time'] ?? '';
            final attendanceStatus = data['attendanceStatus'] ?? 'absent';

            return FutureBuilder<DocumentSnapshot?>(
              future:
                  teacherId.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('teachers')
                          .doc(teacherId)
                          .get()
                      : null,
              builder: (context, teacherSnapshot) {
                String teacherName = 'Unknown Teacher';
                if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
                  teacherName = teacherSnapshot.data!['fullName'] ?? 'Teacher';
                }

                // Use studentName from class data if available, otherwise fetch from students collection
                String finalStudentName =
                    studentName.isNotEmpty ? studentName : 'Unknown Student';

                return FutureBuilder<DocumentSnapshot?>(
                  future:
                      studentId.isNotEmpty && studentName.isEmpty
                          ? FirebaseFirestore.instance
                              .collection('students')
                              .doc(studentId)
                              .get()
                          : null,
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.hasData &&
                        studentSnapshot.data!.exists) {
                      finalStudentName =
                          studentSnapshot.data!['fullName'] ?? 'Student';
                    }

                    // Apply search filter
                    if (searchQuery.isNotEmpty) {
                      final query = searchQuery.toLowerCase();
                      if (!teacherName.toLowerCase().contains(query) &&
                          !finalStudentName.toLowerCase().contains(query)) {
                        return const SizedBox.shrink();
                      }
                    }

                    return _AdminAttendanceCard(
                      teacherName: teacherName,
                      studentName: finalStudentName,
                      date: date,
                      time: time,
                      attendanceStatus: attendanceStatus,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminAttendanceCard extends StatelessWidget {
  final String teacherName;
  final String studentName;
  final String date;
  final String time;
  final String attendanceStatus;
  const _AdminAttendanceCard({
    required this.teacherName,
    required this.studentName,
    required this.date,
    required this.time,
    required this.attendanceStatus,
  });
  @override
  Widget build(BuildContext context) {
    final isPresent = attendanceStatus == 'present';

    // Format date and time properly
    String formattedDateTime = 'No date/time';
    if (date.isNotEmpty || time.isNotEmpty) {
      if (date.isNotEmpty && time.isNotEmpty) {
        formattedDateTime = '$date at $time';
      } else if (date.isNotEmpty) {
        formattedDateTime = date;
      } else if (time.isNotEmpty) {
        formattedDateTime = time;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Card(
        color: Theme.of(context).cardColor,
        shadowColor: Theme.of(context).shadowColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher and Student info
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: appGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                teacherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.school, size: 14, color: appGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isPresent
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      border: Border.all(
                        color: isPresent ? Colors.green : Colors.red,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Date and time
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: appGreen),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedDateTime,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
