import 'package:al_mehdi_online_school/teachers/teacher_schedule_class/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teacher_schedule_class_mobile_provider.dart';
import '../../../constants/colors.dart';

class TeacherScheduleClassMobile extends StatelessWidget {
  const TeacherScheduleClassMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherScheduleClassMobileProvider(),
      child: Consumer<TeacherScheduleClassMobileProvider>(
        builder: (context, provider, _) {
          Color dropdownColor =
          Theme.of(context).brightness == Brightness.dark
              ? darkBackground
              : appLightGreen;
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
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width * 0.03, // Responsive padding
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Let students know when you'll be teaching next.",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 14 : MediaQuery.of(context).size.width * 0.035, // Responsive font size
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.015), // Responsive spacing
                      Card(
                        color: Theme.of(context).cardColor,
                        shadowColor: Theme.of(context).shadowColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width * 0.035), // Responsive padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compact informational section
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 10 : MediaQuery.of(context).size.width * 0.025),
                                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.01),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "💡 Recurring Classes",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.03,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                                    Text(
                                      "Select Schedule Type & Duration for recurring classes, or leave empty for single class",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width * 0.028,
                                        color: Colors.blue.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                              Text(
                                "Student",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              DropdownButtonFormField<String>(
                                value: provider.selectedStudentId,
                                items: provider.assignedStudents
                                    .map(
                                      (student) => DropdownMenuItem<String>(
                                        value: student['id'] as String,
                                        child: Flexible(
                                          child: Text(
                                            student['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: provider.onStudentChanged,
                                dropdownColor: dropdownColor,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: appGreen),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width * 0.03,
                                    vertical: MediaQuery.of(context).size.height * 0.015,
                                  ),
                                ),
                                hint: Text(
                                  'Select Student',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              Text(
                                "Date",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              TextFields(
                                label: 'Select Date',
                                icon: Icons.calendar_today,
                                isDatePicker: true,
                                value: provider.selectedDate,
                                onChanged: provider.onDateChanged,
                                keyboardType: TextInputType.datetime,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              Text(
                                "Select Time",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              TextFields(
                                label: 'Select Time',
                                icon: Icons.access_time,
                                isTimePicker: true,
                                value: provider.selectedTime,
                                onChanged: provider.onTimeChanged,
                                keyboardType: TextInputType.datetime,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              Text(
                                "Schedule Type",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              DropdownButtonFormField<String>(
                                value: provider.selectedScheduleType,
                                items: provider.scheduleTypeOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                        value: option['value'],
                                        child: Flexible(
                                          child: Text(
                                            option['label'] ?? '',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: provider.onScheduleTypeChanged,
                                dropdownColor: dropdownColor,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: appGreen),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width * 0.03,
                                    vertical: MediaQuery.of(context).size.height * 0.015,
                                  ),
                                ),
                                hint: Text(
                                  'Select Schedule Type (Optional)',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              Text(
                                "Duration",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              DropdownButtonFormField<String>(
                                value: provider.selectedDuration,
                                items: provider.durationOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                        value: option['value'],
                                        child: Flexible(
                                          child: Text(
                                            option['label'] ?? '',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: provider.onDurationChanged,
                                dropdownColor: dropdownColor,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: appGreen),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width * 0.03,
                                    vertical: MediaQuery.of(context).size.height * 0.015,
                                  ),
                                ),
                                hint: Text(
                                  'Select Duration (Optional)',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              // Days selection field (only show when working_days or custom_days is selected)
                              if (provider.selectedScheduleType == 'working_days' || provider.selectedScheduleType == 'custom_days') ...[
                                Text(
                                  "Select Days",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.03,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: provider.selectedScheduleType == 'working_days'
                                      ? Text(
                                    'Monday to Friday (automatically selected)',
                                  )
                                      : Wrap(
                                    spacing: MediaQuery.of(context).size.width * 0.02,
                                    runSpacing: MediaQuery.of(context).size.height * 0.008,
                                    children: provider.daysOptions.map((day) {
                                      final isSelected = provider.selectedDays.contains(day['value']);
                                      return GestureDetector(
                                        onTap: () {
                                          provider.onDaySelectionChanged(day['value']!, !isSelected);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context).size.width * 0.025,
                                            vertical: MediaQuery.of(context).size.height * 0.005,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected ? appGreen : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected ? appGreen : Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                color: isSelected ? Colors.white : Colors.grey,
                                                size: MediaQuery.of(context).size.width * 0.035,
                                              ),
                                              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                              Text(
                                                day['label']!,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: MediaQuery.of(context).size.width * 0.028,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (provider.selectedScheduleType == 'custom_days' && provider.selectedDays.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.008),
                                    child: Text(
                                      'Selected: ${provider.selectedDays.map((day) => provider.daysOptions.firstWhere((d) => d['value'] == day)['label']).join(', ')}',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width * 0.026,
                                        color: appGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.018),
                              ],
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                              TextFields(
                                label: 'Description',
                                maxLines: 2,
                                value: provider.descriptionController.text,
                                onChanged: (val) => provider.descriptionController.text = val,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appGreen,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: MediaQuery.of(context).size.height * 0.018,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: provider.isLoading
                                      ? null
                                      : () => provider.scheduleClass(context),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.005),
                                    child: provider.isLoading
                                        ? SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.025,
                                      width: MediaQuery.of(context).size.height * 0.025,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                        : Text(
                                      'Schedule Class',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.03,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
