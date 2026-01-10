import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../services/notification_service.dart';

class TeacherScheduleClassWebProvider extends ChangeNotifier {
  String? selectedStudentId;
  String? selectedStudentName;
  String? selectedDate;
  String? selectedTime;
  List<Map<String, dynamic>> assignedStudents = [];
  late TextEditingController descriptionController;
  Map<String, List<String>> fcmTokens = {};
  bool _isLoading = false;

  // New fields for recurring classes
  String? selectedScheduleType;
  String? selectedDuration;
  List<String> selectedDays = [];

  // Schedule type options
  final List<Map<String, String>> scheduleTypeOptions = [
    {'value': 'working_days', 'label': 'Working Days (Mon-Fri)'},
    {'value': 'weekends', 'label': 'Weekends (Sat-Sun)'},
    {'value': 'custom_days', 'label': 'Custom Days'},
  ];

  // Days options for custom selection
  final List<Map<String, String>> daysOptions = [
    {'value': 'monday', 'label': 'Monday'},
    {'value': 'tuesday', 'label': 'Tuesday'},
    {'value': 'wednesday', 'label': 'Wednesday'},
    {'value': 'thursday', 'label': 'Thursday'},
    {'value': 'friday', 'label': 'Friday'},
    {'value': 'saturday', 'label': 'Saturday'},
    {'value': 'sunday', 'label': 'Sunday'},
  ];

  // Duration options
  final List<Map<String, String>> durationOptions = [
    {'value': '1_week', 'label': '1 Week'},
    {'value': '2_weeks', 'label': '2 Weeks'},
    {'value': '3_weeks', 'label': '3 Weeks'},
    {'value': '4_weeks', 'label': '4 Weeks'},
    {'value': '1_month', 'label': '1 Month'},
    {'value': '1_year', 'label': '1 Year'},
    {'value': '2_years', 'label': '2 Years'},
  ];

  // For displaying scheduled classes
  List<DocumentSnapshot> scheduledClasses = [];

  bool get isLoading => _isLoading;
  String? get description =>
      descriptionController.text.isEmpty ? null : descriptionController.text;

  TeacherScheduleClassWebProvider() {
    descriptionController = TextEditingController();
    loadAssignedStudents();
    loadScheduledClasses();
    // Start the reminder service immediately
    _startReminderService();
    // Pre-initialize notification system for instant notifications
    _initializeNotificationSystem();
  }

  // Pre-initialize notification system to ensure instant notifications
  void _initializeNotificationSystem() {
    // Ensure notification service is ready for instant sending
    Future.microtask(() async {
      try {
        // Warm up notification service if needed
        print('🔔 Teacher notification system ready for instant notifications');
      } catch (e) {
        print('⚠️ Error initializing teacher notification system: $e');
      }
    });
  }

  Future<void> loadAssignedStudents() async {
    final teacherId = FirebaseAuth.instance.currentUser?.uid;
    if (teacherId == null) return;

    fcmTokens.clear();

    final studentsSnapshot =
        await FirebaseFirestore.instance
            .collection('students')
            .where('assignedTeacherId', isEqualTo: teacherId)
            .get();
    assignedStudents =
        studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          final studentId = doc.id;

          if (data['fcmTokens'] != null) {
            final tokens = List<String>.from(data['fcmTokens']);
            fcmTokens[studentId] = tokens;
          }

          return {'id': studentId, 'name': data['fullName'] ?? 'Student'};
        }).toList();
    notifyListeners();
  }

  Future<void> loadScheduledClasses() async {
    final teacherId = FirebaseAuth.instance.currentUser?.uid;
    if (teacherId == null) return;

    try {
      // Fetch classes without orderBy to avoid index requirement
      final query =
          await FirebaseFirestore.instance
              .collection('classes')
              .where('teacherId', isEqualTo: teacherId)
              .get();

      // Filter out documents that don't have required fields and sort in memory
      final docs =
          query.docs.where((doc) {
            final data = doc.data();
            // Only include documents that have the basic required fields
            return data.containsKey('date') &&
                data.containsKey('time') &&
                data.containsKey('status');
          }).toList();

      docs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();

        // Try to get scheduledAt timestamp first
        final aTimestamp = aData['scheduledAt'] as Timestamp?;
        final bTimestamp = bData['scheduledAt'] as Timestamp?;

        // If both have scheduledAt, use that for sorting
        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        }

        // Fallback to date/time string parsing if scheduledAt is missing
        try {
          final aDate = aData['date'] as String? ?? '';
          final aTime = aData['time'] as String? ?? '';
          final bDate = bData['date'] as String? ?? '';
          final bTime = bData['time'] as String? ?? '';

          if (aDate.isNotEmpty &&
              aTime.isNotEmpty &&
              bDate.isNotEmpty &&
              bTime.isNotEmpty) {
            final aDateTime = _parseDateTime(aDate, aTime);
            final bDateTime = _parseDateTime(bDate, bTime);

            if (aDateTime != null && bDateTime != null) {
              return aDateTime.compareTo(bDateTime);
            }
          }
        } catch (e) {
          print('Error parsing date/time for sorting: $e');
        }

        // If all else fails, maintain original order
        return 0;
      });

      scheduledClasses = docs;
      notifyListeners();
    } catch (e) {
      print('Error loading scheduled classes: $e');
      scheduledClasses = [];
      notifyListeners();
    }
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      // Try MM/dd/yyyy first, fallback to yyyy-MM-dd
      try {
        return DateFormat('MM/dd/yyyy hh:mm a').parse('$date $time');
      } catch (_) {
        return DateFormat('yyyy-MM-dd hh:mm a').parse('$date $time');
      }
    } catch (e) {
      return null;
    }
  }

  void onStudentChanged(String? value) {
    selectedStudentId = value;
    selectedStudentName =
        assignedStudents.firstWhere(
          (s) => s['id'] == value,
          orElse: () => {'name': ''},
        )['name'];
    notifyListeners();
  }

  void onDateChanged(String? value) {
    selectedDate = value;
    notifyListeners();
  }

  void onTimeChanged(String? value) {
    selectedTime = value;
    notifyListeners();
  }

  void onDescriptionChanged(String? value) {
    descriptionController.text = value ?? '';
    // Don't call notifyListeners() here to avoid rebuilds while typing
  }

  void onScheduleTypeChanged(String? value) {
    selectedScheduleType = value;
    notifyListeners();
  }

  void onDurationChanged(String? value) {
    selectedDuration = value;
    notifyListeners();
  }

  void onDaySelectionChanged(String day, bool isSelected) {
    if (isSelected) {
      if (!selectedDays.contains(day)) {
        selectedDays.add(day);
      }
    } else {
      selectedDays.remove(day);
    }
    notifyListeners();
  }

  void clearDaySelection() {
    selectedDays.clear();
    notifyListeners();
  }

  Future<void> scheduleClass(BuildContext context) async {
    if (selectedStudentId == null ||
        selectedDate == null ||
        selectedTime == null ||
        description == null ||
        selectedStudentId!.isEmpty ||
        selectedDate!.isEmpty ||
        selectedTime!.isEmpty ||
        description!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate recurring schedule options
    if ((selectedScheduleType != null && selectedDuration == null) ||
        (selectedScheduleType == null && selectedDuration != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select both Schedule Type and Duration for recurring classes, or leave both empty for a single class',
          ),
        ),
      );
      return;
    }

    // Validate custom days selection
    if (selectedScheduleType == 'custom_days' && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one day for custom days schedule',
          ),
        ),
      );
      return;
    }

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        throw Exception('Teacher not logged in');
      }

      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(teacherId)
              .get();
      final teacherName = teacherDoc.data()?['fullName'] ?? 'Teacher';

      DateTime localDateTime;
      try {
        // Try MM/dd/yyyy first, fallback to yyyy-MM-dd
        try {
          localDateTime = DateFormat(
            'MM/dd/yyyy hh:mm a',
          ).parse('$selectedDate $selectedTime');
        } catch (_) {
          localDateTime = DateFormat(
            'yyyy-MM-dd hh:mm a',
          ).parse('$selectedDate $selectedTime');
        }

        if (localDateTime.isBefore(DateTime.now())) {
          throw Exception('Cannot schedule classes in the past');
        }
      } catch (e) {
        throw Exception('Invalid date or time format: $e');
      }

      // Store context-dependent values before async operations
      final contextMounted = context.mounted;
      final bool isRecurring =
          selectedScheduleType != null && selectedDuration != null;

      // Check if recurring scheduling is enabled
      if (isRecurring) {
        await _scheduleRecurringClasses(teacherId, teacherName, localDateTime);
      } else {
        await _scheduleSingleClass(teacherId, teacherName, localDateTime);
      }

      // Reset form
      selectedStudentId = null;
      selectedStudentName = null;
      selectedDate = null;
      selectedTime = null;
      selectedScheduleType = null;
      selectedDuration = null;
      selectedDays.clear();
      descriptionController.clear();

      // Reload scheduled classes
      await loadScheduledClasses();

      if (contextMounted && context.mounted) {
        final message =
            isRecurring
                ? 'Classes scheduled successfully!'
                : 'Class scheduled successfully!';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      // Clear loading state
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleSingleClass(
    String teacherId,
    String teacherName,
    DateTime localDateTime,
  ) async {
    final utcDateTime = localDateTime.toUtc();

    final classData = {
      'date': selectedDate,
      'time': selectedTime,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': selectedStudentId,
      'studentName': selectedStudentName,
      'createdAt': FieldValue.serverTimestamp(),
      'jitsiRoom': '${teacherId}_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'upcoming',
      'scheduledAt': utcDateTime,
      'scheduledAtTimeZone': DateTime.now().timeZoneName,
    };

    // Create class document and get the document reference
    final docRef = await FirebaseFirestore.instance
        .collection('classes')
        .add(classData);

    // Send immediate notifications asynchronously WITHOUT waiting (INSTANT)
    _sendSingleSummaryNotification(selectedStudentId!, teacherName);

    // Schedule reminder notifications asynchronously WITHOUT waiting
    _scheduleClassReminders([
      {
        'classId': docRef.id,
        'studentId': selectedStudentId!,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentName': selectedStudentName!,
        'date': selectedDate!,
        'time': selectedTime!,
        'scheduledAt': utcDateTime,
        'classDateTime': localDateTime,
      },
    ]);
  }

  Future<void> _scheduleRecurringClasses(
    String teacherId,
    String teacherName,
    DateTime startDateTime,
  ) async {
    final List<DateTime> classDates = _generateClassDates(startDateTime);

    if (classDates.isEmpty) {
      throw Exception('No valid class dates generated');
    }

    print(
      'Scheduling ${classDates.length} classes for $selectedScheduleType over $selectedDuration',
    );

    // Batch write for better performance
    final batch = FirebaseFirestore.instance.batch();
    final List<Map<String, String>> notificationData = [];
    final List<Map<String, dynamic>> reminderData = [];

    for (final classDate in classDates) {
      final utcDateTime = classDate.toUtc();
      final formattedDate = DateFormat('MM/dd/yyyy').format(classDate);
      final formattedTime = DateFormat('hh:mm a').format(classDate);

      final classData = {
        'date': formattedDate,
        'time': formattedTime,
        'description': description,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentId': selectedStudentId,
        'studentName': selectedStudentName,
        'createdAt': FieldValue.serverTimestamp(),
        'jitsiRoom': '${teacherId}_${classDate.millisecondsSinceEpoch}',
        'status': 'upcoming',
        'scheduledAt': utcDateTime,
        'scheduledAtTimeZone': DateTime.now().timeZoneName,
        'isRecurring': true,
        'recurringType': selectedScheduleType,
        'recurringDuration': selectedDuration,
      };

      final docRef = FirebaseFirestore.instance.collection('classes').doc();
      batch.set(docRef, classData);

      // Store notification data for immediate processing
      notificationData.add({
        'studentId': selectedStudentId!,
        'teacherName': teacherName,
        'date': formattedDate,
        'time': formattedTime,
      });

      // Store reminder data for scheduling pre-class notifications
      reminderData.add({
        'classId': docRef.id,
        'studentId': selectedStudentId!,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentName': selectedStudentName!,
        'date': formattedDate,
        'time': formattedTime,
        'scheduledAt': utcDateTime,
        'classDateTime': classDate,
      });
    }

    // Commit all classes at once
    await batch.commit();

    // Immediately clear loading state and update UI
    _isLoading = false;
    notifyListeners();

    // Send immediate notifications asynchronously WITHOUT waiting (INSTANT)
    _sendSingleSummaryNotification(selectedStudentId!, teacherName);

    // Schedule reminder notifications asynchronously WITHOUT waiting
    _scheduleClassReminders(reminderData);
  }

  List<DateTime> _generateClassDates(DateTime startDate) {
    final List<DateTime> dates = [];
    DateTime currentDate = startDate;

    // Get end date based on duration
    final DateTime endDate = _getEndDate(startDate);

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (_shouldIncludeDate(currentDate)) {
        dates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  DateTime _getEndDate(DateTime startDate) {
    switch (selectedDuration) {
      case '1_week':
        return startDate.add(const Duration(days: 7));
      case '2_weeks':
        return startDate.add(const Duration(days: 14));
      case '3_weeks':
        return startDate.add(const Duration(days: 21));
      case '4_weeks':
        return startDate.add(const Duration(days: 28));
      case '1_month':
        return DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
          startDate.hour,
          startDate.minute,
        );
      case '1_year':
        return DateTime(
          startDate.year + 1,
          startDate.month,
          startDate.day,
          startDate.hour,
          startDate.minute,
        );
      case '2_years':
        return DateTime(
          startDate.year + 2,
          startDate.month,
          startDate.day,
          startDate.hour,
          startDate.minute,
        );
      default:
        return startDate.add(const Duration(days: 7)); // Default to 1 week
    }
  }

  bool _shouldIncludeDate(DateTime date) {
    final int weekday = date.weekday; // Monday = 1, Sunday = 7

    switch (selectedScheduleType) {
      case 'working_days':
        return weekday >= 1 && weekday <= 5; // Monday to Friday
      case 'weekends':
        return weekday == 6 || weekday == 7; // Saturday and Sunday
      case 'custom_days':
        final dayName = _getDayName(weekday);
        return selectedDays.contains(dayName);
      default:
        return true; // Include all days if no schedule type is selected
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }

  // Send single summary notification instead of multiple notifications (FIRE AND FORGET)
  void _sendSingleSummaryNotification(String studentId, String teacherName) {
    // Fire and forget - immediate execution without blocking UI
    (() async {
      try {
        String scheduleMessage = '';

        // Determine schedule type and create appropriate message
        if (selectedScheduleType != null && selectedDuration != null) {
          // Get duration label
          String durationLabel = selectedDuration ?? '';
          final durationOption = durationOptions.firstWhere(
            (option) => option['value'] == selectedDuration,
            orElse: () => {'label': selectedDuration ?? ''},
          );
          durationLabel = durationOption['label'] ?? selectedDuration ?? '';

          // Get schedule type label
          String scheduleTypeLabel = '';
          if (selectedScheduleType == 'working_days') {
            scheduleTypeLabel = 'Working Days (Mon-Fri)';
          } else if (selectedScheduleType == 'weekends') {
            scheduleTypeLabel = 'Weekends (Sat-Sun)';
          } else if (selectedScheduleType == 'custom_days') {
            scheduleTypeLabel = 'Custom Days (${selectedDays.join(', ')})';
          }

          scheduleMessage =
              'Your classes have been scheduled for $durationLabel on $scheduleTypeLabel';
        } else {
          scheduleMessage =
              'Your class has been scheduled for ${selectedDate!} at ${selectedTime!}';
        }

        // Send notification directly through NotificationService (includes both in-app and FCM)
        await NotificationService.sendClassScheduledNotification(
          receiverId: studentId,
          teacherName: teacherName,
          classDate: selectedDate ?? 'Multiple dates',
          classTime: selectedTime ?? 'Various times',
          customMessage: scheduleMessage,
        );

        print('✅ Web - Class notification sent successfully: $scheduleMessage');
      } catch (e) {
        print('❌ Error in web teacher notification: $e');
      }
    })();
  }

  // Schedule reminder notifications 5 minutes before each class with background support (FIRE AND FORGET)
  void _scheduleClassReminders(List<Map<String, dynamic>> reminderData) {
    // Fire and forget - immediate execution without blocking
    (() async {
      try {
        final batch = FirebaseFirestore.instance.batch();

        for (final data in reminderData) {
          final classDateTime = data['classDateTime'] as DateTime;
          final reminderTime = classDateTime.subtract(
            const Duration(minutes: 5),
          );

          // Only schedule reminders for future classes
          if (reminderTime.isAfter(DateTime.now())) {
            // Store FCM tokens for background notifications
            String? studentFcmTokens;
            String? teacherFcmTokens;

            // Get student FCM tokens
            if (fcmTokens.containsKey(data['studentId'])) {
              final tokens = fcmTokens[data['studentId']] ?? [];
              studentFcmTokens = tokens.where((t) => t.isNotEmpty).join(',');
            }

            // Get teacher FCM tokens
            if (fcmTokens.containsKey(data['teacherId'])) {
              final tokens = fcmTokens[data['teacherId']] ?? [];
              teacherFcmTokens = tokens.where((t) => t.isNotEmpty).join(',');
            }

            final reminderDoc = {
              'classId': data['classId'],
              'studentId': data['studentId'],
              'teacherId': data['teacherId'],
              'teacherName': data['teacherName'],
              'studentName': data['studentName'],
              'classDate': data['date'],
              'classTime': data['time'],
              'reminderTime': reminderTime.toUtc(),
              'classScheduledAt': data['scheduledAt'],
              'status': 'pending',
              'type': 'class_reminder',
              'createdAt': FieldValue.serverTimestamp(),
              // Add FCM tokens for background notifications when app is closed
              'studentFcmTokens': studentFcmTokens ?? '',
              'teacherFcmTokens': teacherFcmTokens ?? '',
              // Mark that this reminder supports background notifications
              'supportsBackgroundNotification': true,
            };

            final docRef =
                FirebaseFirestore.instance.collection('class_reminders').doc();
            batch.set(docRef, reminderDoc);
          }
        }

        await batch.commit();
        print(
          'Teacher scheduled ${reminderData.length} class reminders with background notification support',
        );
      } catch (e) {
        print('Error scheduling teacher class reminders: $e');
      }
    })();
  }

  // Service to check and send reminder notifications
  void _startReminderService() {
    // Start immediately and check for pending reminders every 30 seconds
    _checkPendingReminders();
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkPendingReminders();
    });
  }

  Future<void> _checkPendingReminders() async {
    try {
      final now = DateTime.now().toUtc();
      print('Checking reminders at: $now');

      // Get all pending reminders first (without the reminderTime filter to avoid index issues)
      final pendingReminders =
          await FirebaseFirestore.instance
              .collection('class_reminders')
              .where('status', isEqualTo: 'pending')
              .get();

      print('Found ${pendingReminders.docs.length} total pending reminders');

      // Filter in memory to find reminders that should be sent now
      final remindersToSend =
          pendingReminders.docs.where((doc) {
            final data = doc.data();
            final reminderTime = (data['reminderTime'] as Timestamp).toDate();
            // Check if reminder time has passed (should be sent now or is overdue)
            return reminderTime.isBefore(now.add(const Duration(minutes: 1)));
          }).toList();

      print('Found ${remindersToSend.length} reminders ready to send');

      for (final doc in remindersToSend) {
        final data = doc.data();
        final reminderTime = (data['reminderTime'] as Timestamp).toDate();

        print(
          'Processing reminder for class at ${data['classTime']}, reminder time: $reminderTime',
        );

        // Send the reminder
        await _sendClassReminderNotification(data);

        // Mark as sent
        await doc.reference.update({
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
          'actualSentTime': now,
        });

        print(
          'Reminder sent and marked as sent for class at ${data['classTime']}',
        );
      }
    } catch (e) {
      print('Error in reminder service: $e');
    }
  }

  // Send reminder notification to both teacher and student
  Future<void> _sendClassReminderNotification(
    Map<String, dynamic> reminderData,
  ) async {
    try {
      final studentId = reminderData['studentId'] as String;
      final teacherId = reminderData['teacherId'] as String;
      final teacherName = reminderData['teacherName'] as String;
      final studentName = reminderData['studentName'] as String;
      final classDate = reminderData['classDate'] as String;
      final classTime = reminderData['classTime'] as String;

      print(
        'Sending reminder notification for class: $classDate at $classTime',
      );

      // Send to student
      await NotificationService.sendClassScheduledNotification(
        receiverId: studentId,
        teacherName: teacherName,
        classDate: classDate,
        classTime: 'Please join the class, the time has entered',
      );

      // Send to teacher
      await NotificationService.sendClassScheduledNotification(
        receiverId: teacherId,
        teacherName: 'Class Reminder',
        classDate: classDate,
        classTime:
            'Please join the class with $studentName, the time has entered',
      );

      // Send FCM notifications to student
      if (fcmTokens.containsKey(studentId)) {
        final studentTokens = fcmTokens[studentId] ?? [];
        for (final token in studentTokens.where((t) => t.isNotEmpty)) {
          try {
            final success = await NotificationService.sendFCMNotification(
              title: '🔔 Class Starting Now!',
              body:
                  'Please join the class, the time has entered! Class with $teacherName at $classTime on $classDate',
              token: token,
            );
            if (success) {
              print('✅ FCM notification sent successfully to student');
            } else {
              print(
                '❌ FCM notification failed for student - token may be invalid',
              );
            }
          } catch (e) {
            print('⚠️ FCM notification error for student: $e');
            // Continue processing - don't let FCM failures stop in-app notifications
          }
        }
      }

      // Get teacher FCM tokens and send notification
      try {
        final teacherDoc =
            await FirebaseFirestore.instance
                .collection('teachers')
                .doc(teacherId)
                .get();

        if (teacherDoc.exists) {
          final teacherData = teacherDoc.data()!;
          if (teacherData['fcmTokens'] != null) {
            final teacherTokens = List<String>.from(teacherData['fcmTokens']);
            for (final token in teacherTokens.where((t) => t.isNotEmpty)) {
              try {
                final success = await NotificationService.sendFCMNotification(
                  title: '🔔 Class Starting Now!',
                  body:
                      'Please join the class with $studentName, the time has entered! Scheduled for $classTime on $classDate',
                  token: token,
                );
                if (success) {
                  print('✅ FCM notification sent successfully to teacher');
                } else {
                  print(
                    '❌ FCM notification failed for teacher - token may be invalid',
                  );
                }
              } catch (e) {
                print('⚠️ FCM notification error for teacher: $e');
                // Continue processing - don't let FCM failures stop in-app notifications
              }
            }
          }
        }
      } catch (e) {
        print('Error getting teacher FCM tokens: $e');
      }

      print('Reminder sent successfully for class at $classTime on $classDate');
    } catch (e) {
      print('Error sending class reminder: $e');
    }
  }

  // Manual method to check reminders (useful for testing)
  Future<void> checkRemindersNow() async {
    print('Manual reminder check triggered');
    await _checkPendingReminders();
  }

  // Debug method to check reminder status in database
  Future<void> debugReminders() async {
    try {
      print('=== DEBUGGING REMINDERS ===');
      final now = DateTime.now();
      print('Current time: $now (Local)');
      print('Current time UTC: ${now.toUtc()}');

      // Get all reminders
      final allReminders =
          await FirebaseFirestore.instance.collection('class_reminders').get();

      print('Total reminders in database: ${allReminders.docs.length}');

      for (final doc in allReminders.docs) {
        final data = doc.data();
        final reminderTime = (data['reminderTime'] as Timestamp).toDate();
        final status = data['status'] ?? 'unknown';

        print('---');
        print('Reminder ID: ${doc.id}');
        print('Class Date: ${data['classDate']}');
        print('Class Time: ${data['classTime']}');
        print('Reminder Time: $reminderTime (UTC)');
        print('Reminder Time Local: ${reminderTime.toLocal()}');
        print('Status: $status');
        print(
          'Should send now?: ${reminderTime.isBefore(now.toUtc().add(const Duration(minutes: 1)))}',
        );
      }

      // Get pending reminders specifically
      final pendingReminders =
          await FirebaseFirestore.instance
              .collection('class_reminders')
              .where('status', isEqualTo: 'pending')
              .get();

      print('');
      print('Pending reminders: ${pendingReminders.docs.length}');
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  // Cancel a scheduled class
  Future<void> cancelClass(BuildContext context, String classId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update class status to cancelled
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelledBy': FirebaseAuth.instance.currentUser?.uid,
          });

      // Cancel related reminders
      final reminders =
          await FirebaseFirestore.instance
              .collection('class_reminders')
              .where('classId', isEqualTo: classId)
              .where('status', isEqualTo: 'pending')
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final reminderDoc in reminders.docs) {
        batch.update(reminderDoc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Reload scheduled classes
      await loadScheduledClasses();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show confirmation dialog for cancelling class
  Future<void> showCancelClassDialog(
    BuildContext context,
    String classId,
    String classDate,
    String classTime,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Cancel Class',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3E5C),
            ),
          ),
          content: Text(
            'Are you sure you want to cancel the class scheduled for $classDate at $classTime?',
            style: const TextStyle(color: Color(0xFF8696BB)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(color: Color(0xFF8696BB)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                cancelClass(context, classId);
              },
            ),
          ],
        );
      },
    );
  }
}
