import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_test_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({Key? key}) : super(key: key);

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadNotificationStats();
  }

  Future<void> _loadNotificationStats() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading notification statistics...';
    });

    try {
      final stats = await NotificationTestService.getNotificationStats();
      setState(() {
        _stats = stats;
        _statusMessage = 'Statistics loaded successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load statistics: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runCrossPlatformTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running cross-platform notification tests...';
      _testResults = null;
    });

    try {
      final results = await NotificationTestService.testCrossPlatformNotifications();
      setState(() {
        _testResults = results;
        _statusMessage = 'Cross-platform test completed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSelfNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending test notification to yourself...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Must be logged in');
      }

      // Try to find current user in teachers or students
      bool success = false;
      try {
        success = await NotificationTestService.testNotificationToUser(user.uid, 'teachers');
      } catch (e) {
        success = await NotificationTestService.testNotificationToUser(user.uid, 'students');
      }

      setState(() {
        _statusMessage = success 
          ? 'Self-test notification sent successfully!' 
          : 'Failed to send self-test notification';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Self-test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupInvalidTokens() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cleaning up invalid FCM tokens...';
    });

    try {
      final cleaned = await NotificationTestService.cleanupInvalidTokens();
      setState(() {
        _statusMessage = 'Cleaned up $cleaned invalid tokens';
      });
      await _loadNotificationStats(); // Refresh stats
    } catch (e) {
      setState(() {
        _statusMessage = 'Cleanup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    final platformStats = _stats!['platformDistribution'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Notification Statistics', 
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Total Users: ${_stats!['totalUsers']}'),
            Text('Users with Tokens: ${_stats!['usersWithTokens']}'),
            Text('Coverage: ${_stats!['coverage']}%'),
            Text('Total Tokens: ${_stats!['totalTokens']}'),
            const SizedBox(height: 8),
            Text('Platform Distribution:', 
              style: Theme.of(context).textTheme.titleMedium),
            Text('🤖 Android: ${platformStats['android'] ?? 0}'),
            Text('🍎 iOS: ${platformStats['ios'] ?? 0}'),
            Text('🌐 Web: ${platformStats['web'] ?? 0}'),
            Text('📱 Simulator: ${platformStats['simulator'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsCard() {
    if (_testResults == null) return const SizedBox.shrink();

    final details = _testResults!['details'] as List<Map<String, dynamic>>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧪 Test Results', 
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Total Tests: ${_testResults!['totalTests']}'),
            Text('✅ Successful: ${_testResults!['successfulTests']}', 
              style: const TextStyle(color: Colors.green)),
            Text('❌ Failed: ${_testResults!['failedTests']}', 
              style: const TextStyle(color: Colors.red)),
            
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Details:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final detail = details[index];
                    final isSuccess = detail['status'] == 'success';
                    
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      title: Text('${detail['recipient']} (${detail['recipientType']})'),
                      subtitle: detail['error'] != null 
                        ? Text(detail['error'], style: const TextStyle(fontSize: 12))
                        : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification Debug'),
        backgroundColor: Colors.blue[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                  ? Colors.red[50]
                  : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                        ? Colors.red[700]
                        : Colors.green[700],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSelfNotification,
              icon: const Icon(Icons.person),
              label: const Text('Test Self Notification'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runCrossPlatformTest,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Run Cross-Platform Test'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cleanupInvalidTokens,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Cleanup Invalid Tokens'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadNotificationStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Statistics'),
            ),

            const SizedBox(height: 24),

            // Statistics card
            _buildStatsCard(),

            const SizedBox(height: 16),

            // Test results card
            _buildTestResultsCard(),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Instructions', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Test Self Notification: Sends a notification to your own device\n'
                      '2. Cross-Platform Test: Sends test notifications to all users (Android ↔ iOS)\n'
                      '3. Cleanup Invalid Tokens: Removes expired/invalid FCM tokens\n'
                      '4. Check statistics to see platform distribution and coverage\n\n'
                      '⚠️ Make sure you have permission to send notifications to other users\n'
                      '🔔 Check your notification settings if you don\'t receive notifications',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔧 Debug Info', 
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Platform: ${Theme.of(context).platform}'),
                      Text('User: ${FirebaseAuth.instance.currentUser?.email ?? 'Not logged in'}'),
                      const Text(
                        '\n💡 Tips:\n'
                        '• iOS notifications work on physical devices only\n'
                        '• Check Firebase Console for delivery reports\n'
                        '• Ensure APNS certificates are valid\n'
                        '• Test on both foreground and background states',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}