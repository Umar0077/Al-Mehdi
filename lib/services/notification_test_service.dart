import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

/// Service for testing push notifications across platforms
class NotificationTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test cross-platform notifications (Android to iOS and vice versa)
  static Future<Map<String, dynamic>> testCrossPlatformNotifications() async {
    final results = <String, dynamic>{
      'totalTests': 0,
      'successfulTests': 0,
      'failedTests': 0,
      'details': <Map<String, dynamic>>[],
    };

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to test notifications');
      }

      // Get all users (teachers and students) with FCM tokens
      final teachers = await _firestore.collection('teachers').get();
      final students = await _firestore.collection('students').get();

      final allUsers = <Map<String, dynamic>>[];
      
      // Add teachers
      for (var doc in teachers.docs) {
        final data = doc.data();
        final tokens = data['fcmTokens'] as List<dynamic>? ?? [];
        if (tokens.isNotEmpty) {
          allUsers.add({
            'id': doc.id,
            'type': 'teacher',
            'name': data['name'] ?? 'Teacher',
            'tokens': tokens,
          });
        }
      }

      // Add students
      for (var doc in students.docs) {
        final data = doc.data();
        final tokens = data['fcmTokens'] as List<dynamic>? ?? [];
        if (tokens.isNotEmpty) {
          allUsers.add({
            'id': doc.id,
            'type': 'student',
            'name': data['name'] ?? 'Student',
            'tokens': tokens,
          });
        }
      }

      if (allUsers.isEmpty) {
        throw Exception('No users with FCM tokens found for testing');
      }

      // Test notifications to all users
      for (final user in allUsers) {
        final tokens = user['tokens'] as List<dynamic>;
        for (final token in tokens) {
          if (token is String && token.isNotEmpty) {
            results['totalTests'] = (results['totalTests'] as int) + 1;
            
            try {
              final success = await NotificationService.sendFCMNotification(
                token: token,
                title: '🧪 Cross-Platform Test',
                body: 'This is a test notification from ${_getCurrentUserInfo()} to ${user['name']} (${user['type']})',
                data: {
                  'type': 'test',
                  'senderId': currentUser.uid,
                  'recipientId': user['id'],
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );

              if (success) {
                results['successfulTests'] = (results['successfulTests'] as int) + 1;
                (results['details'] as List<Map<String, dynamic>>).add({
                  'status': 'success',
                  'recipient': user['name'],
                  'recipientType': user['type'],
                  'token': token.substring(0, 20) + '...',
                });
              } else {
                results['failedTests'] = (results['failedTests'] as int) + 1;
                (results['details'] as List<Map<String, dynamic>>).add({
                  'status': 'failed',
                  'recipient': user['name'],
                  'recipientType': user['type'],
                  'token': token.substring(0, 20) + '...',
                  'error': 'FCM request failed',
                });
              }
            } catch (e) {
              results['failedTests'] = (results['failedTests'] as int) + 1;
              (results['details'] as List<Map<String, dynamic>>).add({
                'status': 'error',
                'recipient': user['name'],
                'recipientType': user['type'],
                'token': token.substring(0, 20) + '...',
                'error': e.toString(),
              });
            }

            // Small delay between notifications to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (kDebugMode) {
        print('🧪 Notification Test Results:');
        print('Total Tests: ${results['totalTests']}');
        print('Successful: ${results['successfulTests']}');
        print('Failed: ${results['failedTests']}');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notification test failed: $e');
      }
      results['error'] = e.toString();
      return results;
    }
  }

  /// Test notification to a specific user
  static Future<bool> testNotificationToUser(String userId, String userType) async {
    try {
      final doc = await _firestore.collection(userType).doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final tokens = data['fcmTokens'] as List<dynamic>? ?? [];
      
      if (tokens.isEmpty) {
        throw Exception('User has no FCM tokens');
      }

      bool anySuccess = false;
      for (final token in tokens) {
        if (token is String && token.isNotEmpty) {
          final success = await NotificationService.sendFCMNotification(
            token: token,
            title: '🧪 Individual Test',
            body: 'This is a test notification from ${_getCurrentUserInfo()}',
            data: {
              'type': 'individual_test',
              'senderId': _auth.currentUser?.uid ?? 'unknown',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          if (success) anySuccess = true;
        }
      }

      return anySuccess;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Individual notification test failed: $e');
      }
      return false;
    }
  }

  /// Get current user info for testing
  static String _getCurrentUserInfo() {
    final user = _auth.currentUser;
    return user?.email ?? user?.uid ?? 'Unknown User';
  }

  /// Validate FCM token format
  static bool validateFCMToken(String token) {
    // FCM tokens are typically base64 strings with specific patterns
    if (token.isEmpty) return false;
    if (token.length < 140) return false; // FCM tokens are usually longer
    
    // Check if it's a simulator mock token
    if (token.startsWith('simulator_token_')) return true;
    
    // Basic validation for real FCM tokens
    final fcmTokenPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    return fcmTokenPattern.hasMatch(token);
  }

  /// Clean up all invalid tokens
  static Future<int> cleanupInvalidTokens() async {
    int totalCleaned = 0;
    
    try {
      // Check teachers
      final teachers = await _firestore.collection('teachers').get();
      for (var doc in teachers.docs) {
        final data = doc.data();
        final tokens = List<String>.from(data['fcmTokens'] ?? []);
        final validTokens = tokens.where(validateFCMToken).toList();
        
        if (validTokens.length != tokens.length) {
          await doc.reference.update({'fcmTokens': validTokens});
          totalCleaned += tokens.length - validTokens.length;
        }
      }

      // Check students
      final students = await _firestore.collection('students').get();
      for (var doc in students.docs) {
        final data = doc.data();
        final tokens = List<String>.from(data['fcmTokens'] ?? []);
        final validTokens = tokens.where(validateFCMToken).toList();
        
        if (validTokens.length != tokens.length) {
          await doc.reference.update({'fcmTokens': validTokens});
          totalCleaned += tokens.length - validTokens.length;
        }
      }

      if (kDebugMode) {
        print('🧹 Cleaned up $totalCleaned invalid FCM tokens');
      }

      return totalCleaned;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token cleanup failed: $e');
      }
      return 0;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final teachers = await _firestore.collection('teachers').get();
      final students = await _firestore.collection('students').get();

      int totalUsers = 0;
      int usersWithTokens = 0;
      int totalTokens = 0;
      int androidTokens = 0;
      int iosTokens = 0;
      int webTokens = 0;
      int simulatorTokens = 0;

      // Process teachers
      for (var doc in teachers.docs) {
        totalUsers++;
        final data = doc.data();
        final tokens = List<String>.from(data['fcmTokens'] ?? []);
        if (tokens.isNotEmpty) {
          usersWithTokens++;
          totalTokens += tokens.length;
          
          for (final token in tokens) {
            if (token.startsWith('simulator_token_')) {
              simulatorTokens++;
            } else if (token.length > 160) {
              // iOS tokens are typically longer
              iosTokens++;
            } else if (token.contains(':')) {
              // Android tokens often contain colons
              androidTokens++;
            } else {
              // Web tokens
              webTokens++;
            }
          }
        }
      }

      // Process students
      for (var doc in students.docs) {
        totalUsers++;
        final data = doc.data();
        final tokens = List<String>.from(data['fcmTokens'] ?? []);
        if (tokens.isNotEmpty) {
          usersWithTokens++;
          totalTokens += tokens.length;
          
          for (final token in tokens) {
            if (token.startsWith('simulator_token_')) {
              simulatorTokens++;
            } else if (token.length > 160) {
              iosTokens++;
            } else if (token.contains(':')) {
              androidTokens++;
            } else {
              webTokens++;
            }
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'usersWithTokens': usersWithTokens,
        'totalTokens': totalTokens,
        'platformDistribution': {
          'android': androidTokens,
          'ios': iosTokens,
          'web': webTokens,
          'simulator': simulatorTokens,
        },
        'coverage': totalUsers > 0 ? (usersWithTokens / totalUsers * 100).round() : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get notification stats: $e');
      }
      return {'error': e.toString()};
    }
  }
}