// import 'package:flutter/material.dart';
//
// List<Map<String, dynamic>> studentNotifications = [
//   {
//     'icon': Icons.calendar_today,
//     'text': 'Reminder: Math with Mr. Ariff at 4 PM.',
//     'time': '20 minutes ago',
//     'unread': true,
//   },
//   {
//     'icon': Icons.message,
//     'text': 'Miss Alia replied to your message.',
//     'time': '1 hour ago',
//     'unread': true,
//   },
//   {
//     'icon': Icons.system_update,
//     'text': 'New version 1.3.0 is available.',
//     'time': 'Yesterday',
//     'unread': false,
//   },
//   {
//     'icon': Icons.calendar_today,
//     'text': 'You\'ve got a class with Cikgu Aina tomorrow at 9 AM.',
//     'time': 'Just now',
//     'unread': false,
//   },
//   {
//     'icon': Icons.lock,
//     'text': 'Your password was updated successfully.',
//     'time': '2 hours ago',
//     'unread': false,
//   },
// ];

import 'package:flutter/material.dart';

// ...

List<Map<String, dynamic>> getStudentNotifications() {
  return [
    {
      'icon': Icons.calendar_today,
      'text': 'Reminder: Math with Mr. Ariff at 4 PM.',
      'time': '20 minutes ago',
      'unread': true,
    },
    {
      'icon': Icons.message,
      'text': 'Miss Alia replied to your message.',
      'time': '1 hour ago',
      'unread': true,
    },
    {
      'icon': Icons.system_update,
      'text': 'New version 1.3.0 is available.',
      'time': 'Yesterday',
      'unread': false,
    },
    {
      'icon': Icons.calendar_today,
      'text': 'You\'ve got a class with Cikgu Aina tomorrow at 9 AM.',
      'time': 'Just now',
      'unread': false,
    },
    {
      'icon': Icons.lock,
      'text': 'Your password was updated successfully.',
      'time': '2 hours ago',
      'unread': false,
    },
  ];
}
