import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../students/student_notifications/student_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../teacher_notifications/teacher_notifications.dart';
import 'teacher_attendance_web_provider.dart';

class TeacherAttendanceWebView extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String?> onChanged;


  const TeacherAttendanceWebView({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherAttendanceWebProvider>(
      create: (_) => TeacherAttendanceWebProvider(),
      child: Consumer<TeacherAttendanceWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body:
                provider.isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading attendance data...'),
                        ],
                      ),
                    )
                    : provider.error.isNotEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Data',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchStudents(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : Row(
                      children: [
                        // Sidebar(selectedIndex: 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              _buildHeader(context, provider),
                              const Divider(),

                              // Statistics Dashboard
                              _buildStatisticsSection(provider),

                              // Filters Section
                              _buildFiltersSection(provider),

                              // Content Section
                              Expanded(child: _buildContent(context, provider)),
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

  // Enhanced Header Section
  Widget _buildHeader(
    BuildContext context,
    TeacherAttendanceWebProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          // Title with icon
          Row(
            children: [
              Text(
                'Attendance Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          const Spacer(),
          // Action buttons
          Row(
            children: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: appGreen),
                onPressed:
                    provider.isLoading ? null : () => provider.fetchStudents(),
                tooltip: 'Refresh Data',
              ),
              const SizedBox(width: 8),
              // Export button
              ElevatedButton.icon(
                onPressed: () => _showExportDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
              ),
              const SizedBox(width: 8),
              // Notifications
              StreamBuilder<QuerySnapshot>(
                stream:
                NotificationService.getNotificationsStream(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount =
                        snapshot.data!.docs
                            .where(
                              (doc) =>
                          !(doc['read'] ??
                              false),
                        )
                            .length;
                  }
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                  TeacherNotificationScreen(),
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
                            decoration:
                            const BoxDecoration(
                              color: Colors.red,
                              shape:
                              BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Statistics Dashboard
  Widget _buildStatisticsSection(TeacherAttendanceWebProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Classes',
              provider.totalClasses.toString(),
              Icons.school,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Present',
              provider.presentCount.toString(),
              Icons.check_circle,
              appGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Absent',
              provider.absentCount.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Pending',
              provider.pendingCount.toString(),
              Icons.pending,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Attendance Rate',
              '${provider.attendanceRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              appGreen,
            ),
          ),
        ],
      ),
    );
  }

  // Stat Card Widget
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive font size: scale between 18 and 32 based on card width
        double fontSize = (constraints.maxWidth / 8).clamp(18, 32);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: fontSize),
                  const Spacer(),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced Filters Section
  Widget _buildFiltersSection(TeacherAttendanceWebProvider provider) {
    return Builder(
      builder: (context) {
        Color dropdownColor = Theme.of(context).brightness == Brightness.dark ? darkBackground : appLightGreen;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt, color: appGreen),
                  const SizedBox(width: 8),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => provider.clearFilters(),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Student Filter
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              focusColor: Colors.transparent,
                              hint: const Text('All Students', style: TextStyle(fontSize: 14)),
                              value: provider.selectedStudent == '' ? null : provider.selectedStudent,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Students', style: TextStyle(fontSize: 14)),
                                ),
                                ...provider.students.map(
                                  (student) => DropdownMenuItem(
                                    value: student,
                                    child: Text(student, style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ],
                              onChanged: (value) => provider.setSelectedStudent(value),
                              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
                              dropdownColor: dropdownColor,
                              underline: SizedBox.shrink(),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Date Range Filter
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date Range',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap:
                                      () => _selectDateRange(context, provider),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.date_range,
                                          color: appGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getDateRangeText(provider),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Search Filter
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: provider.searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by student, date, or time...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: appGreen,
                              ),
                              suffixIcon:
                                  provider.searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed:
                                            () =>
                                                provider.searchController
                                                    .clear(),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: appGreen),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  // Content Section with Enhanced Class List
  Widget _buildContent(
    BuildContext context,
    TeacherAttendanceWebProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Section header
          Row(
            children: [
              const Text(
                'Class Records',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Last Updated: ${DateTime.now().toString().substring(0, 16)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Class list
          Expanded(child: _buildEnhancedAttendanceList(context, provider)),
        ],
      ),
    );
  }

  // Enhanced Attendance List
  Widget _buildEnhancedAttendanceList(
    BuildContext context,
    TeacherAttendanceWebProvider provider,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('classes')
              .where(
                'teacherId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .where('status', isEqualTo: 'completed')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading classes...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final classes =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _applyFilters(data, provider);
            }).toList();

        if (classes.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final data = classes[index].data() as Map<String, dynamic>;
            return _buildEnhancedClassCard(
              context,
              classes[index],
              data,
              provider,
            );
          },
        );
      },
    );
  }

  // Enhanced Class Card
  Widget _buildEnhancedClassCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    TeacherAttendanceWebProvider provider,
  ) {
    final studentName = data['studentName'] ?? 'Student';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';
    final attendanceStatus = data['attendanceStatus'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (attendanceStatus) {
      case 'present':
        statusColor = appGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        color: Theme.of(context).scaffoldBackgroundColor,
        shadowColor: Theme.of(context).shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              attendanceStatus == null
                  ? () => _markAttendance(context, doc, studentName)
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Student Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: appGreen.withOpacity(0.1),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: appGreen,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Class Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Menu
                if (attendanceStatus != null) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Reset',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _markAttendance(context, doc, studentName);
                          break;
                        case 'delete':
                          _resetAttendance(doc);
                          break;
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods
  bool _applyFilters(
    Map<String, dynamic> data,
    TeacherAttendanceWebProvider provider,
  ) {
    // Search filter
    final studentName = (data['studentName'] ?? '').toString().toLowerCase();
    final date = (data['date'] ?? '').toString().toLowerCase();
    final time = (data['time'] ?? '').toString().toLowerCase();
    final combined = '$studentName $date $time';
    final matchesSearch =
        provider.searchQuery.isEmpty || combined.contains(provider.searchQuery);

    // Student filter
    final matchesStudent =
        provider.selectedStudent == null ||
        provider.selectedStudent == '' ||
        data['studentName'] == provider.selectedStudent;

    return matchesSearch && matchesStudent;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Classes Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some classes to see attendance records',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText(TeacherAttendanceWebProvider provider) {
    if (provider.startDate == null && provider.endDate == null) {
      return 'Select date range';
    }
    if (provider.startDate != null && provider.endDate != null) {
      return '${provider.formatDate(provider.startDate)} - ${provider.formatDate(provider.endDate)}';
    }
    if (provider.startDate != null) {
      return 'From ${provider.formatDate(provider.startDate)}';
    }
    return 'Until ${provider.formatDate(provider.endDate)}';
  }

  // Dialog Methods
  Future<void> _selectDateRange(
    BuildContext context,
    TeacherAttendanceWebProvider provider,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          provider.startDate != null && provider.endDate != null
              ? DateTimeRange(
                start: provider.startDate!,
                end: provider.endDate!,
              )
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: appGreen, // Use app green instead of purple
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Attendance Data'),
            content: const Text(
              'This feature will be available soon. You\'ll be able to export attendance data to CSV or PDF format.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _markAttendance(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String studentName,
  ) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isPresent = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.how_to_reg, color: appGreen),
                  const SizedBox(width: 8),
                  const Text('Mark Attendance'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mark attendance for $studentName'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPresent = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  isPresent
                                      ? appGreen.withOpacity(0.1)
                                      : null,
                              border: Border.all(
                                color:
                                    isPresent
                                        ? appGreen
                                        : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: isPresent ? appGreen : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Present',
                                  style: TextStyle(
                                    color:
                                        isPresent ? appGreen : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPresent = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  !isPresent
                                      ? Colors.red.withOpacity(0.1)
                                      : null,
                              border: Border.all(
                                color:
                                    !isPresent
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: !isPresent ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Absent',
                                  style: TextStyle(
                                    color:
                                        !isPresent ? Colors.red : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red),),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, isPresent),
                  style: ElevatedButton.styleFrom(backgroundColor: appGreen),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(doc.id)
            .update({'attendanceStatus': result ? 'present' : 'absent'});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attendance marked as ${result ? 'Present' : 'Absent'}',
              ),
              backgroundColor: result ? appGreen : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating attendance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resetAttendance(QueryDocumentSnapshot doc) async {
    try {
      await FirebaseFirestore.instance.collection('classes').doc(doc.id).update(
        {'attendanceStatus': FieldValue.delete()},
      );
    } catch (e) {
      // Handle error silently or show a message
    }
  }
}
