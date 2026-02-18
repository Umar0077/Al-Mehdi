import 'package:al_mehdi_online_school/views/admin_dashboard/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../providers/admin/schedule_class_provider.dart';
import '../../../providers/unassigned_user/notifications_provider.dart';

class ScheduleClass extends StatelessWidget {
  const ScheduleClass({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 900;
    if (isWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ScheduleClassContent(), // Only show content, no sidebar or Row
      );
    } else {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Schedule Class',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: SingleChildScrollView(child: ScheduleClassContent()),
        ),
      );
    }
  }
}

class ScheduleClassContent extends StatefulWidget {
  const ScheduleClassContent({super.key});

  @override
  State<ScheduleClassContent> createState() => _ScheduleClassContentState();
}

class _ScheduleClassContentState extends State<ScheduleClassContent> {
  bool showAllFilteredClasses = false;

  @override
  Widget build(BuildContext context) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(),
      child: ChangeNotifierProvider(
        create: (_) => ScheduleClassProvider(),
        child: Consumer<ScheduleClassProvider>(
          builder: (context, provider, _) {
            final isLoading = provider.isLoading;
            final isWeb = MediaQuery.of(context).size.width >= 900;
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            Widget teacherDropdown = DropdownButtonFormField<String>(
              dropdownColor: dropdownColor,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
              decoration: InputDecoration(
                labelText: 'Teacher',
                labelStyle: TextStyle(fontSize: 15, color: textColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: appGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(fontSize: 15, color: textColor),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Select Teacher',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                ),
                ...provider.filteredTeachers.map<DropdownMenuItem<String>>(
                  (t) => DropdownMenuItem<String>(
                    value: t['uid'] as String,
                    child: Text(
                      t['name'] as String,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                provider.setSelectedTeacherId(val);
              },
            );
            // ...existing code...
            Widget studentDropdown;
            if (provider.selectedTeacherId != null &&
                provider.filteredStudents.isEmpty) {
              studentDropdown = const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No students assigned to this teacher.',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              );
            } else {
              final selectedStudent = provider.selectedStudentId != null
                  ? provider.filteredStudents.firstWhere(
                      (s) => s['uid'] == provider.selectedStudentId,
                      orElse: () => {},
                    )
                  : null;
              final selectedStudentName =
                  (selectedStudent != null && selectedStudent.isNotEmpty)
                      ? selectedStudent['name'] as String
                      : null;

              studentDropdown = GestureDetector(
                onTap: () async {
                  String? tempSelected = provider.selectedStudentId;
                  String searchQuery = '';
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) {
                      return StatefulBuilder(
                        builder: (ctx, setSheetState) {
                          final allStudents = provider.filteredStudents;
                          final filtered = allStudents
                              .where((s) => (s['name'] as String)
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                              .toList();
                          return Container(
                            height: MediaQuery.of(ctx).size.height * 0.75,
                            decoration: BoxDecoration(
                              color: isDark ? darkBackground : Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Handle bar
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Header row with title and action buttons
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Select Student',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      // Cross button
                                      GestureDetector(
                                        onTap: () => Navigator.pop(ctx),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Tick button
                                      GestureDetector(
                                        onTap: () {
                                          provider.setSelectedStudentId(
                                              tempSelected);
                                          Navigator.pop(ctx);
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: appLightGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: appGreen,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Search field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search student...',
                                      hintStyle: TextStyle(
                                          color: Colors.grey.shade500),
                                      prefixIcon: const Icon(Icons.search,
                                          color: appGreen),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade100,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: TextStyle(color: textColor),
                                    onChanged: (val) =>
                                        setSheetState(() => searchQuery = val),
                                  ),
                                ),
                                const Divider(height: 1),
                                // Student list
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No students found.',
                                            style: TextStyle(
                                                color: Colors.grey.shade500),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          itemCount: filtered.length,
                                          itemBuilder: (_, i) {
                                            final student = filtered[i];
                                            final uid =
                                                student['uid'] as String;
                                            final name =
                                                student['name'] as String;
                                            final isSelected =
                                                tempSelected == uid;
                                            return InkWell(
                                              onTap: () => setSheetState(() =>
                                                  tempSelected =
                                                      isSelected ? null : uid),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? appGreen
                                                              : Colors
                                                                  .grey.shade400,
                                                          width: 2,
                                                        ),
                                                        color: isSelected
                                                            ? appGreen
                                                            : Colors.transparent,
                                                      ),
                                                      child: isSelected
                                                          ? const Icon(
                                                              Icons.check,
                                                              size: 14,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color: textColor,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                  .normal,
                                                        ),
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
                        },
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: provider.selectedStudentId != null
                          ? appGreen
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedStudentName ?? 'Select Student',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedStudentName != null
                                ? textColor
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: provider.selectedStudentId != null
                            ? appGreen
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }
            Widget dateField = TextFields(
              label: 'Select Date',
              icon: Icons.calendar_today,
              isDatePicker: true,
              controller: TextEditingController(text: provider.selectedDate),
              onChanged: (val) => provider.setSelectedDate(val),
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
            );
            Widget timeField = TextFields(
              label: 'Select Time',
              icon: Icons.access_time,
              isTimePicker: true,
              controller: TextEditingController(text: provider.selectedTime),
              onChanged: (val) => provider.setSelectedTime(val),
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
            );
            Widget descField = TextFields(
              label: 'Description',
              maxLines: 2,
              controller: provider.descriptionController,
              onChanged: (val) => provider.setDescription(val),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            );

            // Schedule Type Dropdown
            Widget scheduleTypeDropdown = DropdownButtonFormField<String>(
              dropdownColor: dropdownColor,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
              decoration: InputDecoration(
                labelText: 'Schedule Type (Optional)',
                labelStyle: TextStyle(fontSize: 15, color: textColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: appGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(fontSize: 15, color: textColor),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Select Schedule Type',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                ),
                ...provider.scheduleTypeOptions.map<DropdownMenuItem<String>>(
                  (option) => DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(
                      option['label']!,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ),
                ),
              ],
              onChanged: (val) => provider.setSelectedScheduleType(val),
            );

            // Duration Dropdown
            Widget durationDropdown = DropdownButtonFormField<String>(
              dropdownColor: dropdownColor,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: appGreen),
              decoration: InputDecoration(
                labelText: 'Duration (Optional)',
                labelStyle: TextStyle(fontSize: 15, color: textColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: appGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(fontSize: 15, color: textColor),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Select Duration',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                ),
                ...provider.durationOptions.map<DropdownMenuItem<String>>(
                  (option) => DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(
                      option['label']!,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ),
                ),
              ],
              onChanged: (val) => provider.setSelectedDuration(val),
            );

            // Custom Days Selection
            Widget customDaysSelection =
                provider.selectedScheduleType == 'custom_days'
                    ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Days',
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                provider.daysOptions.map((day) {
                                  final isSelected = provider.selectedDays
                                      .contains(day['value']);
                                  return FilterChip(
                                    label: Text(
                                      day['label']!,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      provider.onDaySelectionChanged(
                                        day['value']!,
                                        selected,
                                      );
                                    },
                                    selectedColor: appGreen,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: appLightGreen,
                                    side: BorderSide(
                                      color:
                                          isSelected ? appGreen : Colors.grey,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink();
            Widget scheduleButton = SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    provider.isScheduling
                        ? null
                        : () => provider.scheduleClass(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child:
                      provider.isScheduling
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Scheduling...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                          : const Text(
                            'Schedule Class',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            );
            if (isWeb) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Classes',
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule a Class',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Let students know when you\'ll be teaching next.',
                            ),
                            const SizedBox(height: 24),
                            Card(
                              color: Theme.of(context).cardColor,
                              shadowColor: Theme.of(context).shadowColor,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Card radius
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: teacherDropdown),
                                        const SizedBox(width: 25),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Student',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              studentDropdown,
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(child: dateField),
                                        const SizedBox(width: 25),
                                        Expanded(child: timeField),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(child: scheduleTypeDropdown),
                                        const SizedBox(width: 25),
                                        Expanded(child: durationDropdown),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    if (provider.selectedScheduleType ==
                                        'custom_days')
                                      Column(
                                        children: [
                                          customDaysSelection,
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    Row(children: [Expanded(child: descField)]),
                                    const SizedBox(height: 40),
                                    scheduleButton,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Admin Class Management Section
                            const Text(
                              'Manage Scheduled Classes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Theme.of(context).cardColor,
                              shadowColor: Theme.of(context).shadowColor,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Filter Classes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            dropdownColor: dropdownColor,
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: appGreen,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Filter by Teacher',
                                              labelStyle: TextStyle(
                                                fontSize: 15,
                                                color: textColor,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: appGreen,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: textColor,
                                            ),
                                            items: [
                                              DropdownMenuItem<String>(
                                                value: null,
                                                child: Text(
                                                  'All Teachers',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              ...provider.teachers.map<
                                                DropdownMenuItem<String>
                                              >(
                                                (t) => DropdownMenuItem<String>(
                                                  value: t['uid'] as String,
                                                  child: Text(
                                                    t['name'] as String,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged:
                                                (val) => provider
                                                    .setFilterTeacherId(val),
                                          ),
                                        ),
                                        const SizedBox(width: 25),
                                        Expanded(
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            dropdownColor: dropdownColor,
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: appGreen,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Filter by Student',
                                              labelStyle: TextStyle(
                                                fontSize: 15,
                                                color: textColor,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: appGreen,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: textColor,
                                            ),
                                            items: [
                                              DropdownMenuItem<String>(
                                                value: null,
                                                child: Text(
                                                  'All Students',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              ...provider.filterStudents.map<
                                                DropdownMenuItem<String>
                                              >(
                                                (s) => DropdownMenuItem<String>(
                                                  value: s['uid'] as String,
                                                  child: Text(
                                                    s['name'] as String,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged:
                                                (val) => provider
                                                    .setFilterStudentId(val),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFields(
                                            label: 'Start Date',
                                            icon: Icons.calendar_today,
                                            isDatePicker: true,
                                            controller: TextEditingController(
                                              text:
                                                  provider.filterStartDate ??
                                                  '',
                                            ),
                                            onChanged:
                                                (val) =>
                                                    provider.setFilterStartDate(
                                                      val.isEmpty ? null : val,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 25),
                                        Expanded(
                                          child: TextFields(
                                            label: 'End Date',
                                            icon: Icons.calendar_today,
                                            isDatePicker: true,
                                            controller: TextEditingController(
                                              text:
                                                  provider.filterEndDate ?? '',
                                            ),
                                            onChanged:
                                                (val) =>
                                                    provider.setFilterEndDate(
                                                      val.isEmpty ? null : val,
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed:
                                              () => provider.clearFilters(),
                                          child: const Text('Clear Filters'),
                                        ),
                                        const Spacer(),
                                        if (provider
                                            .filteredScheduledClasses
                                            .isNotEmpty)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            onPressed:
                                                () => provider
                                                    .showCancelAllClassesDialog(
                                                      context,
                                                    ),
                                            child: Text(
                                              'Cancel All (${provider.filteredScheduledClasses.length})',
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    if (provider
                                        .filteredScheduledClasses
                                        .isNotEmpty) ...[
                                      const Text(
                                        'Filtered Classes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...(showAllFilteredClasses
                                              ? provider
                                                  .filteredScheduledClasses
                                              : provider
                                                  .filteredScheduledClasses
                                                  .take(10))
                                          .map((classData) {
                                            return Card(
                                              color:
                                                  Theme.of(context).cardColor,
                                              shadowColor:
                                                  Theme.of(context).shadowColor,
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${classData['teacherName']} → ${classData['studentName']}',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            '${classData['date']} at ${classData['time']}',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[700],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          if (classData['description'] !=
                                                                  null &&
                                                              classData['description']
                                                                  .toString()
                                                                  .isNotEmpty) ...[
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              classData['description'],
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      onPressed:
                                                          () => provider
                                                              .showCancelClassDialog(
                                                                context,
                                                                classData,
                                                              ),
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                      if (provider
                                              .filteredScheduledClasses
                                              .length >
                                          10)
                                        Center(
                                          child: IconButton(
                                            icon: Icon(
                                              showAllFilteredClasses
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              size: 32,
                                            ),
                                            tooltip:
                                                showAllFilteredClasses
                                                    ? 'Show less'
                                                    : 'Show more',
                                            onPressed: () {
                                              setState(() {
                                                showAllFilteredClasses =
                                                    !showAllFilteredClasses;
                                              });
                                            },
                                          ),
                                        ),
                                    ] else ...[
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.search_off,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No classes found with current filters',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Let students know when you'll be teaching next.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: Theme.of(context).cardColor,
                      shadowColor: Theme.of(context).shadowColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            teacherDropdown,
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                studentDropdown,
                              ],
                            ),
                            const SizedBox(height: 20),
                            dateField,
                            const SizedBox(height: 20),
                            timeField,
                            const SizedBox(height: 20),
                            scheduleTypeDropdown,
                            const SizedBox(height: 20),
                            durationDropdown,
                            const SizedBox(height: 20),
                            if (provider.selectedScheduleType == 'custom_days')
                              Column(
                                children: [
                                  customDaysSelection,
                                  const SizedBox(height: 20),
                                ],
                              ),
                            descField,
                            const SizedBox(height: 40),
                            scheduleButton,
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Admin Class Management Section for Mobile
                    const Text(
                      'Manage Scheduled Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).cardColor,
                      shadowColor: Theme.of(context).shadowColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Classes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              dropdownColor: dropdownColor,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: appGreen,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Filter by Teacher',
                                labelStyle: const TextStyle(fontSize: 15),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: appGreen),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(fontSize: 15),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'All Teachers',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                ...provider.teachers
                                    .map<DropdownMenuItem<String>>(
                                      (t) => DropdownMenuItem<String>(
                                        value: t['uid'] as String,
                                        child: Text(
                                          t['name'] as String,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged:
                                  (val) => provider.setFilterTeacherId(val),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              dropdownColor: dropdownColor,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: appGreen,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Filter by Student',
                                labelStyle: const TextStyle(fontSize: 15),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: appGreen),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(fontSize: 15),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'All Students',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                ...provider.filterStudents
                                    .map<DropdownMenuItem<String>>(
                                      (s) => DropdownMenuItem<String>(
                                        value: s['uid'] as String,
                                        child: Text(
                                          s['name'] as String,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged:
                                  (val) => provider.setFilterStudentId(val),
                            ),
                            const SizedBox(height: 20),
                            TextFields(
                              label: 'Start Date',
                              icon: Icons.calendar_today,
                              isDatePicker: true,
                              controller: TextEditingController(
                                text: provider.filterStartDate ?? '',
                              ),
                              onChanged:
                                  (val) => provider.setFilterStartDate(
                                    val.isEmpty ? null : val,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            TextFields(
                              label: 'End Date',
                              icon: Icons.calendar_today,
                              isDatePicker: true,
                              controller: TextEditingController(
                                text: provider.filterEndDate ?? '',
                              ),
                              onChanged:
                                  (val) => provider.setFilterEndDate(
                                    val.isEmpty ? null : val,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () => provider.clearFilters(),
                                    child: const Text('Clear Filters'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (provider
                                    .filteredScheduledClasses
                                    .isNotEmpty)
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed:
                                          () => provider
                                              .showCancelAllClassesDialog(
                                                context,
                                              ),
                                      child: Text(
                                        'Cancel All (${provider.filteredScheduledClasses.length})',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.filteredScheduledClasses.isNotEmpty) ...[
                      const Text(
                        'Filtered Classes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(showAllFilteredClasses
                              ? provider.filteredScheduledClasses
                              : provider.filteredScheduledClasses.take(10))
                          .map((classData) {
                            return Card(
                              color: Theme.of(context).cardColor,
                              shadowColor: Theme.of(context).shadowColor,
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${classData['teacherName']} → ${classData['studentName']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${classData['date']} at ${classData['time']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (classData['description'] != null &&
                                        classData['description']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        classData['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed:
                                            () =>
                                                provider.showCancelClassDialog(
                                                  context,
                                                  classData,
                                                ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      if (provider.filteredScheduledClasses.length > 10)
                        Center(
                          child: IconButton(
                            icon: Icon(
                              showAllFilteredClasses
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 32,
                            ),
                            tooltip:
                                showAllFilteredClasses
                                    ? 'Show less'
                                    : 'Show more',
                            onPressed: () {
                              setState(() {
                                showAllFilteredClasses =
                                    !showAllFilteredClasses;
                              });
                            },
                          ),
                        ),
                    ] else ...[
                      Card(
                        color: Theme.of(context).cardColor,
                        shadowColor: Theme.of(context).shadowColor,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No classes found with current filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class TextFields extends StatelessWidget {
  final String label;
  final int maxLines;
  final IconData? icon;
  final bool isDatePicker;
  final bool isTimePicker;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const TextFields({
    super.key,
    required this.label,
    this.maxLines = 1,
    this.icon,
    this.isDatePicker = false,
    this.isTimePicker = false,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController internalController =
        controller ?? TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap:
          (isDatePicker || isTimePicker)
              ? () async {
                FocusScope.of(context).unfocus(); // Hide keyboard

                if (isDatePicker) {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: appGreen, // Header and buttons
                            onPrimary: Color(0xFFe5faf3),
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.green, // Button text color
                            ),
                          ),
                          dialogTheme: DialogThemeData(
                            backgroundColor: Color(0xFFe5faf3),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    final formatted = DateFormat(
                      'MM/dd/yyyy',
                    ).format(pickedDate);
                    internalController.text = formatted;
                    if (onChanged != null) onChanged!(formatted);
                  }
                }

                if (isTimePicker) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: appGreen, // Header and buttons
                            onPrimary: Color(0xFFe5faf3),
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedTime != null) {
                    final now = DateTime.now();
                    final time = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    final formatted = DateFormat('hh:mm a').format(time);
                    internalController.text = formatted;
                    if (onChanged != null) onChanged!(formatted);
                  }
                }
              }
              : null,
      child: AbsorbPointer(
        absorbing: isDatePicker || isTimePicker,
        child: TextField(
          cursorColor: appGreen,
          controller: internalController,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15, color: textColor),
          decoration: InputDecoration(
            label: Text(
              label,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
            floatingLabelStyle: TextStyle(color: appGreen),
            prefixIcon: icon != null ? Icon(icon, color: appGreen) : null,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: appGreen),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;
  final List<String> options;

  const DropdownField({
    super.key,
    required this.label,
    this.options = const ['Math', 'Science', 'English'],
  });

  @override
  Widget build(BuildContext context) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    return DropdownButtonFormField<String>(
      dropdownColor: dropdownColor,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: appGreen),
      hint: Text(label, style: TextStyle(fontSize: 15, color: Colors.black)),
      style: TextStyle(color: Colors.black),
      items:
          options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontSize: 15)),
                ),
              )
              .toList(),
      onChanged: (val) {},
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: appGreen),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
