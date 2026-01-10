import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../providers/teachers/attendance/teacher_attendance_mobile_provider.dart';

class TeacherAttendanceMobileView extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const TeacherAttendanceMobileView({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherAttendanceMobileProvider>(
      create: (_) => TeacherAttendanceMobileProvider(),
      child: Consumer<TeacherAttendanceMobileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, provider),
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
                    ? _buildErrorState(context, provider)
                    : RefreshIndicator(
                      onRefresh: provider.refreshData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statistics Section
                            _buildStatisticsSection(provider),
                            const SizedBox(height: 16),

                            // Filters Section
                            _buildFiltersSection(context, provider),
                            const SizedBox(height: 16),

                            // Classes Header
                            _buildClassesHeader(),
                            const SizedBox(height: 8),

                            // Classes List
                            _buildEnhancedAttendanceList(context, provider),
                          ],
                        ),
                      ),
                    ),
          );
        },
      ),
    );
  }

  // Enhanced AppBar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TeacherAttendanceMobileProvider provider,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: provider.isLoading ? null : () => provider.refreshData(),
          tooltip: 'Refresh',
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 6),
                      Text('Export', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 18),
                      SizedBox(width: 6),
                      Text('Clear Filters', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            switch (value) {
              case 'export':
                _showExportDialog(context);
                break;
              case 'clear':
                provider.clearFilters();
                break;
            }
          },
        ),
      ],
    );
  }

  // Error State Widget
  Widget _buildErrorState(
    BuildContext context,
    TeacherAttendanceMobileProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.refreshData(),
              style: ElevatedButton.styleFrom(backgroundColor: appGreen),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Statistics Section
  Widget _buildStatisticsSection(TeacherAttendanceMobileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // First Row
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                'Total',
                provider.totalClasses.toString(),
                Icons.school,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                'Present',
                provider.presentCount.toString(),
                Icons.check_circle,
                appGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second Row
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                'Absent',
                provider.absentCount.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                'Pending',
                provider.pendingCount.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Attendance Rate Card
        _buildMobileStatCard(
          'Attendance Rate',
          '${provider.attendanceRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          appGreen,
          isFullWidth: true,
        ),
      ],
    );
  }

  // Mobile Stat Card
  Widget _buildMobileStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Mobile Filters Section
  Widget _buildFiltersSection(
    BuildContext context,
    TeacherAttendanceMobileProvider provider,
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      shadowColor: Theme.of(context).shadowColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, color: appGreen, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider.selectedStudent != null ||
                    provider.startDate != null ||
                    provider.searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () => provider.clearFilters(),
                    child: const Text('Clear', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Student Filter
            const Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    'All Students',
                    style: TextStyle(fontSize: 13),
                  ),
                  value:
                      provider.selectedStudent == ''
                          ? null
                          : provider.selectedStudent,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'All Students',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    ...provider.students.map(
                      (student) => DropdownMenuItem(
                        value: student,
                        child: Text(
                          student,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged:
                      (value) => provider.setSelectedStudent(value, onChanged),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: appGreen,
                    size: 20,
                  ),
                  dropdownColor: appLightGreen,
                  underline: SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date Range Filter
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _selectDateRange(context, provider),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: appGreen, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getDateRangeText(provider),
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Filter
            const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: provider.searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by student, date...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: appGreen, size: 18),
                suffixIcon:
                    provider.searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => provider.searchController.clear(),
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: appGreen),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Classes Header
  Widget _buildClassesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Class Records',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          'Updated: ${DateTime.now().toString().substring(11, 16)}',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  // Enhanced Attendance List for Mobile
  Widget _buildEnhancedAttendanceList(
    BuildContext context,
    TeacherAttendanceMobileProvider provider,
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
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
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

        return Column(
          children:
              classes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildEnhancedMobileClassCard(
                  context,
                  doc,
                  data,
                  provider,
                );
              }).toList(),
        );
      },
    );
  }

  // Enhanced Mobile Class Card
  Widget _buildEnhancedMobileClassCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    TeacherAttendanceMobileProvider provider,
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        color: Theme.of(context).scaffoldBackgroundColor,
        shadowColor: Theme.of(context).shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap:
              attendanceStatus == null
                  ? () => _markAttendance(context, doc, studentName)
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Student Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: appGreen.withOpacity(0.1),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appGreen,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Button for marked attendance
                if (attendanceStatus != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => _markAttendance(context, doc, studentName),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: appGreen,
                            side: const BorderSide(color: appGreen),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _resetAttendance(doc),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                    ],
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
    TeacherAttendanceMobileProvider provider,
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Classes Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some classes to see attendance records',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Results Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText(TeacherAttendanceMobileProvider provider) {
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
    TeacherAttendanceMobileProvider provider,
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
                  const Icon(Icons.how_to_reg, color: appGreen, size: 20),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                                  isPresent ? appGreen.withOpacity(0.1) : null,
                              border: Border.all(
                                color:
                                    isPresent ? appGreen : Colors.grey.shade300,
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
                                    color: isPresent ? appGreen : Colors.grey,
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
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
