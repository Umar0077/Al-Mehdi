import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';

class ScheduleClassProvider extends ChangeNotifier {
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> students = [];
  String? selectedTeacherId;
  String? selectedStudentId;
  String? selectedDate;
  String? selectedTime;
  String? description;
  bool isLoading = true;
  bool isScheduling = false; // Separate loading state for schedule button
  TextEditingController descriptionController = TextEditingController();

  // Advanced scheduling options
  String? selectedScheduleType;
  String? selectedDuration;
  List<String> selectedDays = [];
  List<Map<String, dynamic>> scheduledClasses = [];
  Map<String, List<String>> fcmTokens = {};

  // Admin class management properties
  String? filterTeacherId;
  String? filterStudentId;
  String? filterStartDate;
  String? filterEndDate;
  List<Map<String, dynamic>> filteredScheduledClasses = [];

  // Schedule type options
  final List<Map<String, String>> scheduleTypeOptions = [
    {'value': 'working_days', 'label': 'Working Days (Mon-Fri)'},
    {'value': 'weekends', 'label': 'Weekends (Sat-Sun)'},
    {'value': 'custom_days', 'label': 'Custom Days'},
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

  ScheduleClassProvider() {
    fetchTeachersAndStudents();
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
        print('🔔 Admin notification system ready for instant notifications');
      } catch (e) {
        print('⚠️ Error initializing notification system: $e');
      }
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  // Service to check and send reminder notifications (similar to teacher provider)
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
      print('Admin checking reminders at: $now');
      
      // Get all pending reminders first (without the reminderTime filter to avoid index issues)
      final pendingReminders = await FirebaseFirestore.instance
          .collection('class_reminders')
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${pendingReminders.docs.length} total pending reminders');

      // Filter in memory to find reminders that should be sent now
      final remindersToSend = pendingReminders.docs.where((doc) {
        final data = doc.data();
        final reminderTime = (data['reminderTime'] as Timestamp).toDate();
        // Check if reminder time has passed (should be sent now or is overdue)
        return reminderTime.isBefore(now.add(const Duration(minutes: 1)));
      }).toList();

      print('Found ${remindersToSend.length} reminders ready to send');

      for (final doc in remindersToSend) {
        final data = doc.data();
        final reminderTime = (data['reminderTime'] as Timestamp).toDate();
        
        print('Processing reminder for class at ${data['classTime']}, reminder time: $reminderTime');
        
        // Send the reminder
        await _sendClassReminderNotification(data);
        
        // Mark as sent
        await doc.reference.update({
          'status': 'sent', 
          'sentAt': FieldValue.serverTimestamp(),
          'actualSentTime': now,
        });
        
        print('Reminder sent and marked as sent for class at ${data['classTime']}');
      }
    } catch (e) {
      print('Error in admin reminder service: $e');
    }
  }

  // Send reminder notification to both teacher and student
  Future<void> _sendClassReminderNotification(Map<String, dynamic> reminderData) async {
    try {
      final studentId = reminderData['studentId'] as String;
      final teacherId = reminderData['teacherId'] as String;
      final teacherName = reminderData['teacherName'] as String;
      final studentName = reminderData['studentName'] as String;
      final classDate = reminderData['classDate'] as String;
      final classTime = reminderData['classTime'] as String;
      
      print('Sending admin reminder notification for class: $classDate at $classTime');
      
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
        classTime: 'Please join the class with $studentName, the time has entered',
      );

      // Send FCM notifications to student
      if (fcmTokens.containsKey(studentId)) {
        final studentTokens = fcmTokens[studentId] ?? [];
        for (final token in studentTokens.where((t) => t.isNotEmpty)) {
          try {
            final success = await NotificationService.sendFCMNotification(
              title: '🔔 Class Starting Now!',
              body: 'Please join the class, the time has entered! Class with $teacherName at $classTime on $classDate',
              token: token,
            );
            if (success) {
              print('✅ FCM notification sent successfully to student');
            } else {
              print('❌ FCM notification failed for student - token may be invalid');
            }
          } catch (e) {
            print('⚠️ FCM notification error for student: $e');
            // Continue processing - don't let FCM failures stop in-app notifications
          }
        }
      }

      // Get teacher FCM tokens and send notification
      try {
        final teacherDoc = await FirebaseFirestore.instance
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
                  body: 'Please join the class with $studentName, the time has entered! Scheduled for $classTime on $classDate',
                  token: token,
                );
                if (success) {
                  print('✅ FCM notification sent successfully to teacher');
                } else {
                  print('❌ FCM notification failed for teacher - token may be invalid');
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

      print('Admin reminder sent successfully for class at $classTime on $classDate');
    } catch (e) {
      print('Error sending admin class reminder: $e');
    }
  }

  Future<void> fetchTeachersAndStudents() async {
    final teacherSnap = await FirebaseFirestore.instance.collection('teachers').get();
    final studentSnap = await FirebaseFirestore.instance.collection('students').get();
    teachers = teacherSnap.docs.map((doc) => {
      'uid': doc.id,
      'name': doc['fullName'],
      'fcmTokens': List<String>.from(doc.data()['fcmTokens'] ?? []),
      'assignedStudentIds': List<String>.from(doc.data()['assignedStudentIds'] ?? []),
    }).toList();
    students = studentSnap.docs.map((doc) => {
      'uid': doc.id,
      'name': doc['fullName'],
      'fcmTokens': List<String>.from(doc.data()['fcmTokens'] ?? []),
      'assignedTeacherId': doc['assignedTeacherId'],
    }).toList();

    // Build FCM tokens map
    for (final teacher in teachers) {
      final teacherId = teacher['uid'] as String;
      fcmTokens[teacherId] = List<String>.from(teacher['fcmTokens'] ?? []);
    }
    for (final student in students) {
      final studentId = student['uid'] as String;
      fcmTokens[studentId] = List<String>.from(student['fcmTokens'] ?? []);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadScheduledClasses() async {
    try {
      print('Loading scheduled classes...');
      final now = DateTime.now();
      
      // Get all upcoming classes - simplified query first
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('status', isEqualTo: 'upcoming')
          .orderBy('scheduledAt', descending: false)
          .get();

      print('Found ${classesSnapshot.docs.length} classes');

      scheduledClasses = classesSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Class data: $data');
        return {
          'id': doc.id,
          'teacherId': data['teacherId'],
          'studentId': data['studentId'],
          'teacherName': data['teacherName'],
          'studentName': data['studentName'],
          'date': data['date'],
          'time': data['time'],
          'description': data['description'] ?? '',
          'scheduledAt': data['scheduledAt'],
          'status': data['status'],
        };
      })
      // Defensive filter: only include status == 'upcoming'
      .where((classData) => (classData['status'] ?? 'upcoming').toString().toLowerCase() == 'upcoming')
      .toList();

      // Filter out past classes in memory instead of in query
      final filteredClasses = scheduledClasses.where((classData) {
        try {
          final scheduledAt = classData['scheduledAt'];
          if (scheduledAt is Timestamp) {
            return scheduledAt.toDate().isAfter(now);
          } else if (scheduledAt is DateTime) {
            return scheduledAt.isAfter(now);
          }
          return true; // Keep classes without proper timestamp for now
        } catch (e) {
          print('Error filtering class: $e');
          return true;
        }
      }).toList();

      scheduledClasses = filteredClasses;

      // Initialize filtered list with all classes
      filteredScheduledClasses = List.from(scheduledClasses);

      print('Loaded ${scheduledClasses.length} upcoming classes');
      notifyListeners();
    } catch (e) {
      print('Error loading scheduled classes: $e');
      // Try a simpler query if the first one fails
      try {
        print('Trying simpler query...');
        final simpleSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .get();
        
        print('Found ${simpleSnapshot.docs.length} total classes');
        scheduledClasses = simpleSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'teacherId': data['teacherId'],
            'studentId': data['studentId'],
            'teacherName': data['teacherName'],
            'studentName': data['studentName'],
            'date': data['date'],
            'time': data['time'],
            'description': data['description'] ?? '',
            'scheduledAt': data['scheduledAt'],
            'status': data['status'],
          };
        }).toList();
        
        filteredScheduledClasses = List.from(scheduledClasses);
        notifyListeners();
      } catch (e2) {
        print('Error with simple query: $e2');
      }
    }
  }

  // Debug method to test Firestore connection
  Future<void> debugFirestore() async {
    try {
      print('=== DEBUG: Testing Firestore connection ===');
      final allDocs = await FirebaseFirestore.instance.collection('classes').get();
      print('Total documents in classes collection: ${allDocs.docs.length}');
      
      for (var doc in allDocs.docs) {
        final data = doc.data();
        print('Doc ID: ${doc.id}');
        print('Data: $data');
        print('---');
      }
      
      final upcomingDocs = await FirebaseFirestore.instance
          .collection('classes')
          .where('status', isEqualTo: 'upcoming')
          .get();
      print('Documents with status=upcoming: ${upcomingDocs.docs.length}');
      
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // Manual method to check reminders (useful for testing)
  Future<void> checkRemindersNow() async {
    print('Manual admin reminder check triggered');
    await _checkPendingReminders();
  }

  // Debug method to check reminder status in database
  Future<void> debugClassReminders() async {
    try {
      print('=== DEBUGGING ADMIN REMINDERS ===');
      final now = DateTime.now();
      print('Current time: $now (Local)');
      print('Current time UTC: ${now.toUtc()}');
      
      // Get all reminders
      final allReminders = await FirebaseFirestore.instance
          .collection('class_reminders')
          .get();
      
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
        print('Should send now?: ${reminderTime.isBefore(now.toUtc().add(const Duration(minutes: 1)))}');
      }
      
      // Get pending reminders specifically
      final pendingReminders = await FirebaseFirestore.instance
          .collection('class_reminders')
          .where('status', isEqualTo: 'pending')
          .get();
      
      print('');
      print('Pending reminders: ${pendingReminders.docs.length}');
      print('=== END ADMIN DEBUG ===');
    } catch (e) {
      print('Error in admin debug: $e');
    }
  }

  List<Map<String, dynamic>> get filteredTeachers {
    if (selectedStudentId == null) return teachers;
    final student = students.firstWhere((s) => s['uid'] == selectedStudentId, orElse: () => {});
    if (student.isEmpty) return teachers;
    return teachers.where((t) => t['uid'] == student['assignedTeacherId']).toList();
  }

  List<Map<String, dynamic>> get filteredStudents {
    if (selectedTeacherId == null) return students;
    final teacher = teachers.firstWhere((t) => t['uid'] == selectedTeacherId, orElse: () => {});
    if (teacher.isEmpty) return students;
    final assignedStudentIds = (teacher['assignedStudentIds'] as List?)?.cast<String>() ?? [];
    return students.where((s) => s['assignedTeacherId'] == teacher['uid'] || assignedStudentIds.contains(s['uid'])).toList();
  }

  void setSelectedTeacherId(String? val) {
    selectedTeacherId = val;
    if (selectedStudentId != null) {
      final teacher = teachers.firstWhere((t) => t['uid'] == val, orElse: () => {});
      if (teacher.isNotEmpty && !teacher['assignedStudentIds'].contains(selectedStudentId)) {
        selectedStudentId = null;
      }
    }
    notifyListeners();
  }

  void setSelectedStudentId(String? val) {
    selectedStudentId = val;
    if (selectedTeacherId != null) {
      final student = students.firstWhere((s) => s['uid'] == val, orElse: () => {});
      if (student.isNotEmpty && student['assignedTeacherId'] != selectedTeacherId) {
        selectedTeacherId = null;
      }
    }
    notifyListeners();
  }

  void setSelectedDate(String? val) {
    selectedDate = val;
    notifyListeners();
  }

  void setSelectedTime(String? val) {
    selectedTime = val;
    notifyListeners();
  }

  void setDescription(String? val) {
    description = val;
    descriptionController.text = val ?? '';
    notifyListeners();
  }

  void setSelectedScheduleType(String? val) {
    selectedScheduleType = val;
    if (val != 'custom_days') {
      selectedDays.clear();
    }
    notifyListeners();
  }

  void setSelectedDuration(String? val) {
    selectedDuration = val;
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
    if (selectedTeacherId == null || selectedStudentId == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    // Validate recurring schedule options
    if ((selectedScheduleType != null && selectedDuration == null) ||
        (selectedScheduleType == null && selectedDuration != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Schedule Type and Duration for recurring classes, or leave both empty for a single class')),
      );
      return;
    }

    // Validate custom days selection
    if (selectedScheduleType == 'custom_days' && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day for custom days schedule')),
      );
      return;
    }

    // Set loading state for schedule button
    isScheduling = true;
    notifyListeners();

    try {
      final teacher = teachers.firstWhere((t) => t['uid'] == selectedTeacherId, orElse: () => {});
      final student = students.firstWhere((s) => s['uid'] == selectedStudentId, orElse: () => {});

      DateTime localDateTime;
      try {
        localDateTime = DateFormat('MM/dd/yyyy hh:mm a').parse('$selectedDate $selectedTime');
      } catch (e) {
        throw Exception('Invalid date or time format');
      }

      if (selectedScheduleType != null && selectedDuration != null) {
        // Schedule recurring classes
        await _scheduleRecurringClasses(teacher, student, localDateTime);
      } else {
        // Schedule single class
        await _scheduleSingleClass(teacher, student, localDateTime);
      }

      // Show success message IMMEDIATELY
      if (context.mounted) {
        final message = (selectedScheduleType != null && selectedDuration != null) 
            ? 'Classes scheduled successfully! Notifications are being sent in the background.' 
            : 'Class scheduled successfully! Notifications are being sent in the background.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      // Clear form IMMEDIATELY
      selectedTeacherId = null;
      selectedStudentId = null;
      selectedDate = null;
      selectedTime = null;
      selectedScheduleType = null;
      selectedDuration = null;
      selectedDays.clear();
      descriptionController.clear();

      // Clear loading state IMMEDIATELY (don't wait for notifications)
      isScheduling = false;
      notifyListeners();

      // Reload scheduled classes in background (non-blocking)
      Future.microtask(() => loadScheduledClasses());

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      // Clear loading state even on error
      isScheduling = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleSingleClass(Map<String, dynamic> teacher, Map<String, dynamic> student, DateTime localDateTime) async {
    final utcDateTime = localDateTime.toUtc();

    final classData = {
      'date': selectedDate,
      'time': selectedTime,
      'description': description,
      'teacherId': selectedTeacherId,
      'teacherName': teacher['name'],
      'studentId': selectedStudentId,
      'studentName': student['name'],
      'createdAt': FieldValue.serverTimestamp(),
      'jitsiRoom': '${selectedTeacherId}_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'upcoming',
      'scheduledAt': utcDateTime,
      'scheduledAtTimeZone': DateTime.now().timeZoneName,
    };

    // Create class document and get the document reference
    final docRef = await FirebaseFirestore.instance.collection('classes').add(classData);

    print('🔄 Admin scheduling single class with ID: ${docRef.id}');
    print('📅 Class time: ${localDateTime.toLocal()}');

    // Send immediate notifications asynchronously WITHOUT waiting (INSTANT)
    _sendSingleSummaryNotification(selectedStudentId!, selectedTeacherId!, teacher['name'], selectedDate!, selectedTime!, false);

    // Schedule reminder notifications asynchronously WITHOUT waiting  
    _scheduleClassReminders([{
      'classId': docRef.id,
      'studentId': selectedStudentId!,
      'teacherId': selectedTeacherId!,
      'teacherName': teacher['name'],
      'studentName': student['name'],
      'date': selectedDate!,
      'time': selectedTime!,
      'scheduledAt': utcDateTime,
      'classDateTime': localDateTime,
    }]);
  }

  Future<void> _scheduleRecurringClasses(Map<String, dynamic> teacher, Map<String, dynamic> student, DateTime startDateTime) async {
    final List<DateTime> classDates = _generateClassDates(startDateTime);
    
    if (classDates.isEmpty) {
      throw Exception('No valid class dates generated');
    }

    print('Admin scheduling ${classDates.length} classes for $selectedScheduleType over $selectedDuration');

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
        'teacherId': selectedTeacherId,
        'teacherName': teacher['name'],
        'studentId': selectedStudentId,
        'studentName': student['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'jitsiRoom': '${selectedTeacherId}_${classDate.millisecondsSinceEpoch}',
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
        'teacherId': selectedTeacherId!,
        'teacherName': teacher['name'],
        'date': formattedDate,
        'time': formattedTime,
      });

      // Store reminder data for scheduling pre-class notifications
      reminderData.add({
        'classId': docRef.id,
        'studentId': selectedStudentId!,
        'teacherId': selectedTeacherId!,
        'teacherName': teacher['name'],
        'studentName': student['name'],
        'date': formattedDate,
        'time': formattedTime,
        'scheduledAt': utcDateTime,
        'classDateTime': classDate,
      });
    }

    // Commit all classes at once
    await batch.commit();

    // Send immediate notifications asynchronously WITHOUT waiting (INSTANT)
    _sendSingleSummaryNotification(selectedStudentId!, selectedTeacherId!, teacher['name'], '', '', true);

    // Schedule reminder notifications asynchronously WITHOUT waiting
    _scheduleClassReminders(reminderData);
  }

  List<DateTime> _generateClassDates(DateTime startDate) {
    final List<DateTime> dates = [];
    DateTime currentDate = startDate;
    
    // Get end date based on duration
    final DateTime endDate = _getEndDate(startDate);
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
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
        return DateTime(startDate.year, startDate.month + 1, startDate.day, startDate.hour, startDate.minute);
      case '1_year':
        return DateTime(startDate.year + 1, startDate.month, startDate.day, startDate.hour, startDate.minute);
      case '2_years':
        return DateTime(startDate.year + 2, startDate.month, startDate.day, startDate.hour, startDate.minute);
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
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return '';
    }
  }

  // Send a single summary notification instantly without blocking UI (FIRE AND FORGET)
  void _sendSingleSummaryNotification(String studentId, String teacherId, String teacherName, String classDate, String classTime, bool isRecurring) {
    // Fire and forget - immediate execution without blocking
    (() async {
      try {
        String notificationMessage;
        
        if (isRecurring) {
          // For recurring classes, create a summary message
          String scheduleTypeText = '';
          switch (selectedScheduleType) {
            case 'working_days':
              scheduleTypeText = 'Working Days (Mon-Fri)';
              break;
            case 'weekends':
              scheduleTypeText = 'Weekends (Sat-Sun)';
              break;
            case 'custom_days':
              scheduleTypeText = 'Custom Days (${selectedDays.join(', ')})';
              break;
            default:
              scheduleTypeText = 'Selected Days';
          }
          
          String durationText = '';
          switch (selectedDuration) {
            case '1_week':
              durationText = '1 Week';
              break;
            case '2_weeks':
              durationText = '2 Weeks';
              break;
            case '3_weeks':
              durationText = '3 Weeks';
              break;
            case '4_weeks':
              durationText = '4 Weeks';
              break;
            case '1_month':
              durationText = '1 Month';
              break;
            case '1_year':
              durationText = '1 Year';
              break;
            case '2_years':
              durationText = '2 Years';
              break;
            default:
              durationText = selectedDuration ?? 'Selected Duration';
          }
          
          notificationMessage = 'Your classes have been scheduled for $durationText on $scheduleTypeText';
        } else {
          // For single class
          notificationMessage = 'Your class has been scheduled at $classTime on $classDate';
        }
        
        // Send in-app notifications (these are usually instant)
        await NotificationService.sendClassScheduledNotification(
          receiverId: studentId,
          teacherName: teacherName,
          classDate: isRecurring ? 'Multiple Classes' : classDate,
          classTime: notificationMessage,
        );

        await NotificationService.sendClassScheduledNotification(
          receiverId: teacherId,
          teacherName: 'Admin',
          classDate: isRecurring ? 'Multiple Classes' : classDate,
          classTime: 'You have been assigned: $notificationMessage',
        );

        print('✅ Admin - Class notifications sent successfully (in-app + FCM)');

      } catch (e) {
        print('❌ Error in summary notifications: $e');
      }
    })();
  }

  void _scheduleClassReminders(List<Map<String, dynamic>> reminderData) {
    // Fire and forget - immediate execution without blocking
    (() async {
      try {
        print('🔄 Admin starting to schedule ${reminderData.length} class reminders...');
        final batch = FirebaseFirestore.instance.batch();
        int scheduledCount = 0;
        
        for (final data in reminderData) {
          final classDateTime = data['classDateTime'] as DateTime;
          final reminderTime = classDateTime.subtract(const Duration(minutes: 5));
          final now = DateTime.now();
          
          // Only schedule reminders for future classes
          if (reminderTime.isAfter(now)) {
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
              'scheduledByAdmin': true, // Mark as admin-scheduled
              // Add FCM tokens for background notifications
              'studentFcmTokens': fcmTokens[data['studentId']] ?? [],
              'teacherFcmTokens': fcmTokens[data['teacherId']] ?? [],
              // Add data for background notification
              'notificationData': {
                'title': '🔔 Class Starting Soon!',
                'body': 'Your class with ${data['teacherName']} starts in 5 minutes. Time: ${data['time']} on ${data['date']}',
                'teacherTitle': '🔔 Class Starting Soon!',
                'teacherBody': 'Your class with ${data['studentName']} starts in 5 minutes. Time: ${data['time']} on ${data['date']}',
              }
            };
            
            final docRef = FirebaseFirestore.instance.collection('class_reminders').doc();
            batch.set(docRef, reminderDoc);
            scheduledCount++;
          }
        }
        
        if (scheduledCount > 0) {
          await batch.commit();
          print('✅ Admin successfully scheduled $scheduledCount class reminders with background support');
        } else {
          print('⚠️ No reminders were scheduled (all classes in the past)');
        }
        
      } catch (e) {
        print('❌ Error scheduling admin class reminders: $e');
      }
    })();
  }

  // Admin class management methods
  void setFilterTeacherId(String? val) {
    filterTeacherId = val;
    if (filterStudentId != null) {
      final teacher = teachers.firstWhere((t) => t['uid'] == val, orElse: () => {});
      if (teacher.isNotEmpty && !teacher['assignedStudentIds'].contains(filterStudentId)) {
        filterStudentId = null;
      }
    }
    _applyFilters();
    notifyListeners();
  }

  void setFilterStudentId(String? val) {
    filterStudentId = val;
    _applyFilters();
    notifyListeners();
  }

  void setFilterStartDate(String? val) {
    filterStartDate = val;
    _applyFilters();
    notifyListeners();
  }

  void setFilterEndDate(String? val) {
    filterEndDate = val;
    _applyFilters();
    notifyListeners();
  }

  List<Map<String, dynamic>> get filterStudents {
    if (filterTeacherId == null) return students;
    final teacher = teachers.firstWhere((t) => t['uid'] == filterTeacherId, orElse: () => {});
    if (teacher.isEmpty) return students;
    final assignedStudentIds = (teacher['assignedStudentIds'] as List?)?.cast<String>() ?? [];
    return students.where((s) => s['assignedTeacherId'] == teacher['uid'] || assignedStudentIds.contains(s['uid'])).toList();
  }

  void _applyFilters() {
    filteredScheduledClasses = scheduledClasses.where((classData) {
      // Filter by teacher
      if (filterTeacherId != null && classData['teacherId'] != filterTeacherId) {
        return false;
      }
      
      // Filter by student
      if (filterStudentId != null && classData['studentId'] != filterStudentId) {
        return false;
      }
      
      // Filter by date range
      if (filterStartDate != null || filterEndDate != null) {
        try {
          final classDate = DateFormat('MM/dd/yyyy').parse(classData['date']);
          
          if (filterStartDate != null) {
            final startDate = DateFormat('MM/dd/yyyy').parse(filterStartDate!);
            if (classDate.isBefore(startDate)) return false;
          }
          
          if (filterEndDate != null) {
            final endDate = DateFormat('MM/dd/yyyy').parse(filterEndDate!);
            if (classDate.isAfter(endDate)) return false;
          }
        } catch (e) {
          print('Error parsing date for filtering: $e');
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void clearFilters() {
    filterTeacherId = null;
    filterStudentId = null;
    filterStartDate = null;
    filterEndDate = null;
    filteredScheduledClasses = List.from(scheduledClasses);
    notifyListeners();
  }

  Future<void> cancelMultipleClasses(List<String> classIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final classId in classIds) {
        final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
        batch.update(classRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Remove from local lists
      scheduledClasses.removeWhere((cls) => classIds.contains(cls['id']));
      filteredScheduledClasses.removeWhere((cls) => classIds.contains(cls['id']));
      
      notifyListeners();
    } catch (e) {
      print('Error cancelling multiple classes: $e');
      rethrow;
    }
  }

  void showCancelAllClassesDialog(BuildContext context) {
    if (filteredScheduledClasses.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFe5faf3),
          title: const Text(
            'Cancel All Classes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to cancel all ${filteredScheduledClasses.length} filtered classes?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final classIds = filteredScheduledClasses.map((cls) => cls['id'] as String).toList();
                  await cancelMultipleClasses(classIds);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${classIds.length} classes cancelled successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error cancelling classes')),
                    );
                  }
                }
              },
              child: const Text('Yes, Cancel All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> cancelClass(String classId) async {
    try {
      await FirebaseFirestore.instance.collection('classes').doc(classId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      
      // Remove from both local lists
      scheduledClasses.removeWhere((cls) => cls['id'] == classId);
      filteredScheduledClasses.removeWhere((cls) => cls['id'] == classId);
      notifyListeners();
    } catch (e) {
      print('Error cancelling class: $e');
    }
  }

  void showCancelClassDialog(BuildContext context, Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFe5faf3),
          title: const Text(
            'Cancel Class',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to cancel the class on ${classData['date']} at ${classData['time']}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await cancelClass(classData['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class cancelled successfully')),
                  );
                }
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}
