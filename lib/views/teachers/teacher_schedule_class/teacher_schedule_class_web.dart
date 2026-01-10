import 'package:al_mehdi_online_school/views/teachers/teacher_schedule_class/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teacher_schedule_class_web_provider.dart';
import '../../students/student_notifications/student_notifications.dart';
import '../../../services/notification_service.dart';
import '../../../../constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherScheduleClassWeb extends StatelessWidget {
  const TeacherScheduleClassWeb({super.key});

  @override
  Widget build(BuildContext context) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    return ChangeNotifierProvider(
      create: (_) => TeacherScheduleClassWebProvider(),
      child: Consumer<TeacherScheduleClassWebProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with navigation
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Schedule a Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Spacer(),
                      // Notification Icon
                      StreamBuilder<QuerySnapshot>(
                        stream: NotificationService.getNotificationsStream(),
                        builder: (context, snapshot) {
                          int unreadCount = 0;
                          if (snapshot.hasData) {
                            unreadCount =
                                snapshot.data!.docs
                                    .where((doc) => !(doc['read'] ?? false))
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
                                          (_) =>
                                              const StudentNotificationScreen(),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Theme.of(context).cardColor,
                          shadowColor: Theme.of(context).shadowColor,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                // Informational section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "💡 Tip: Recurring Classes",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "• Fill the date and time for the first class\n• Select 'Schedule Type' and 'Duration' to automatically schedule multiple classes\n• Leave both optional fields empty to schedule a single class",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Student",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          DropdownButtonFormField<String>(
                                            initialValue:
                                                provider.selectedStudentId,
                                            items:
                                                provider.assignedStudents
                                                    .map(
                                                      (
                                                        student,
                                                      ) => DropdownMenuItem<
                                                        String
                                                      >(
                                                        value:
                                                            student['id']
                                                                as String,
                                                        child: Text(
                                                          student['name'] ?? '',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                Theme.of(
                                                                          context,
                                                                        ).brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                provider.onStudentChanged,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                            selectedItemBuilder:
                                                (context) =>
                                                    provider.assignedStudents
                                                        .map(
                                                          (student) => Align(
                                                            alignment:
                                                                Alignment
                                                                    .centerLeft,
                                                            child: Text(
                                                              student['name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                            dropdownColor: dropdownColor,
                                            decoration: InputDecoration(
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
                                            hint: Text(
                                              'Select Student',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Select Date",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextFields(
                                            label: 'Select Date',
                                            icon: Icons.calendar_today,
                                            isDatePicker: true,
                                            value: provider.selectedDate,
                                            onChanged: provider.onDateChanged,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Select Time",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextFields(
                                            label: 'Select Time',
                                            icon: Icons.access_time,
                                            isTimePicker: true,
                                            value: provider.selectedTime,
                                            onChanged: provider.onTimeChanged,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Schedule Type",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          DropdownButtonFormField<String>(
                                            initialValue:
                                                provider.selectedScheduleType,
                                            items:
                                                provider.scheduleTypeOptions
                                                    .map(
                                                      (
                                                        option,
                                                      ) => DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: option['value'],
                                                        child: Text(
                                                          option['label'] ?? '',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                Theme.of(
                                                                          context,
                                                                        ).brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                provider.onScheduleTypeChanged,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                            selectedItemBuilder:
                                                (context) =>
                                                    provider.scheduleTypeOptions
                                                        .map(
                                                          (option) => Align(
                                                            alignment:
                                                                Alignment
                                                                    .centerLeft,
                                                            child: Text(
                                                              option['label'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                            dropdownColor: dropdownColor,
                                            decoration: InputDecoration(
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
                                            hint: Text(
                                              'Select Schedule Type (Optional)',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Duration",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          DropdownButtonFormField<String>(
                                            initialValue:
                                                provider.selectedDuration,
                                            items:
                                                provider.durationOptions
                                                    .map(
                                                      (
                                                        option,
                                                      ) => DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: option['value'],
                                                        child: Text(
                                                          option['label'] ?? '',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                Theme.of(
                                                                          context,
                                                                        ).brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                provider.onDurationChanged,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                            selectedItemBuilder:
                                                (context) =>
                                                    provider.durationOptions
                                                        .map(
                                                          (option) => Align(
                                                            alignment:
                                                                Alignment
                                                                    .centerLeft,
                                                            child: Text(
                                                              option['label'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                            dropdownColor: dropdownColor,
                                            decoration: InputDecoration(
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
                                            hint: Text(
                                              'Select Duration (Optional)',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Days selection field (only show when working_days or custom_days is selected)
                                if (provider.selectedScheduleType ==
                                        'working_days' ||
                                    provider.selectedScheduleType ==
                                        'custom_days')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          "Select Days",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child:
                                            provider.selectedScheduleType ==
                                                    'working_days'
                                                ? const Text(
                                                  'Monday to Friday (automatically selected)',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                )
                                                : Wrap(
                                                  spacing: 10,
                                                  runSpacing: 10,
                                                  children:
                                                      provider.daysOptions.map((
                                                        day,
                                                      ) {
                                                        final isSelected =
                                                            provider
                                                                .selectedDays
                                                                .contains(
                                                                  day['value'],
                                                                );
                                                        return InkWell(
                                                          onTap: () {
                                                            provider
                                                                .onDaySelectionChanged(
                                                                  day['value']!,
                                                                  !isSelected,
                                                                );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  isSelected
                                                                      ? appGreen
                                                                      : Colors
                                                                          .transparent,
                                                              border: Border.all(
                                                                color:
                                                                    isSelected
                                                                        ? appGreen
                                                                        : Colors
                                                                            .grey,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  isSelected
                                                                      ? Icons
                                                                          .check_box
                                                                      : Icons
                                                                          .check_box_outline_blank,
                                                                  color:
                                                                      isSelected
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .grey,
                                                                  size: 18,
                                                                ),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                Text(
                                                                  day['label']!,
                                                                  style: TextStyle(
                                                                    color:
                                                                        isSelected
                                                                            ? Colors.white
                                                                            : Colors.grey,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                      ),
                                      if (provider.selectedScheduleType ==
                                              'custom_days' &&
                                          provider.selectedDays.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Selected: ${provider.selectedDays.map((day) => provider.daysOptions.firstWhere((d) => d['value'] == day)['label']).join(', ')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: appGreen,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                if (provider.selectedScheduleType ==
                                        'working_days' ||
                                    provider.selectedScheduleType ==
                                        'custom_days')
                                  const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              "Description",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextFields(
                                            label: 'Description',
                                            maxLines: 2,
                                            controller:
                                                provider.descriptionController,
                                            onChanged:
                                                provider.onDescriptionChanged,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: appGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    onPressed:
                                        provider.isLoading
                                            ? null
                                            : () =>
                                                provider.scheduleClass(context),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child:
                                          provider.isLoading
                                              ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : const Text(
                                                'Schedule Class',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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
