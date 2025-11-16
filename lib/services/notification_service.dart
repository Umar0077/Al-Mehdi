import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {


  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;


//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

  static Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "sample-firebase-ai-app-456c6",
        "private_key_id": "46df537de3b33b58d1f541e2dd749b897bb7b6a5",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCyFiamqGGh3JAG\nEfPGrYBBxrauQRrTNGSNkjdaVGg0O+U0mRDC61AhYX8HcqgSATGrjkhsuHYrGyM+\ny271LnqAgwqcGk6pubEMvakJWlqWEqBKc0qzUBID9ogz3RjY4Qmh5JBcA4wXVV7V\npORdd5soNFq5Ag/ogQRF61swesKueDfsEiJVwkWe4wPLh8f2GYToiGbChyAWhI39\nIQR6F2YeQNliLAp4LZwYN+N53IM5q57IPutZbI9vQ/yyjVJMTeI+oSotDBKFTW7o\nGdjzi1gOKnIWx1fRyTlaValR9ug7VeB/UEBras2rmIwrWMaCITSTMDXQBiHTp+2c\nLr9zNCx/AgMBAAECggEAEhMMdjK1wgNMPMl6p+n5D/P2m4XxDomNQQ8bfhf+AXso\nvqdgW6AdYF3wUhWxeC5V17cXo60vFR3qfFeSWeEPPtbN71z+Kdy2Wvgu3Uul0QBv\n805zQPK5+Vv+o+DnQi/I1f0IJ8aWY9Hez6kuIkxe23xAzvEmIy9g+yWxeiCjfKh8\nkG5mKah+GUUfLWZZ5J3Bbw9Ikl/Zfs7TNEdMY43slPMs++MWVRdINJxiURTJ5rF1\nLqLIobTN2IZESCKjrbhuaMSKKTQkyvVWXB6+UwV/FnEavcUJSSNNgAArdk4IR4QR\nZ8XGNZAxRBlPtS2PcImcAIHgJrhpVtWzzdIotB/JcQKBgQDXyWd2IHhogRWrwpbC\nGJVodDO+Iu6Hv7gVIn5WeV/yF5Xa75e4FhQ4fTbsCHvKvyyEb4SFjUhB2GcV/x9E\nPQZqM9SmtBxuKBUBsP0HM2x/iEUpaz3DegMPxwQWcbugouubzji10NCdbog2eR9j\nLfl8AOwjgehJa+CpH5QgKcM2cQKBgQDTRixBtfwlwGdQvZ7IcL6XUFYiqVE0pnSk\nnEQqxBFCOl22pYi/czjDp8JK2MVFIcnBHA3FSRMsktYsXf2VCnu19gR/GD5eVQR+\noe5KPqyrElRQPNsTIihR0l+9FBgAqTOZizGs2EhLIU+xVeHX8TiTtwukhAQYSQZ1\ncSfGPqBp7wKBgQCmy9WfZ6XrEayQoc8qpRoILZo5ZIMAh19hZtJFQXi6hyScoQqj\njt1+dLtZY41cwL1GeXT0TqsFyqKUTCn88zbcLMg5O4umUnE6Z3aOdF9vjQP46h5J\n1Sw8q9crCirAFm8MdjE7yPcYWfIMOT/byBPKmGPvZmEJL8vurqwu2Fk+4QKBgCAg\nta4wbG2ZOpzOmQzGCFWeQ9r1gIHPJkG5+au/MRivI30Y4xip/uHR6vvSxvziTHnv\nODDeEepfUe5hRKSbeYCMLtbc6u8RYqOXIFNuAHfrS6L//hiEwzjeEuz/1z6SfGRH\nBIDSSvwRzrqa4sMhzYa4+S5FXRIMWM0XLgM5ls9FAoGAD7q7v8ZH6VsbSbzz9xF9\n3I9oIyLvpr6CzI/ag9QciDjqnaqP/YoT+CpHHKc42TYgQu/zauBIuVKibj/1PIz3\nNfwQWbKovosMbv0OFCN382BEQVWQiCyRbJUzkRP2lGYu2XTUSH9GoSG978tIfh1I\ninlytNsXv1XPomulpL7nnoI=\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@sample-firebase-ai-app-456c6.iam.gserviceaccount.com",
        "client_id": "112631122197812416486",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40sample-firebase-ai-app-456c6.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;

    return accessServerKey;
  }

  
 
  /// Sends a push notification using Firebase HTTP v1 API
  static Future<bool> sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final accessToken = await getServerKeyToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final projectId = 'sample-firebase-ai-app-456c6';
    final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
    final payload = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'android': {
          'priority': 'HIGH',
          'notification': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'channel_id': 'chat_notifications',
            'image': data?['imageUrl'],
          },
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default', 'badge': 1, 'content-available': 1},
          },
        },
        'data': data ?? {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "type": "general"
        },
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      print('[FCM] Status Code: ${response.statusCode}');
      print('[FCM] Body: ${response.body}');

      // Handle token cleanup for invalid tokens
      if (response.statusCode == 404) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['error']?['details']?[0]?['errorCode'] == 'UNREGISTERED') {
          print('[FCM] Token is invalid/expired, cleaning up: $token');
          await _cleanupInvalidToken(token);
        }
      }

      return response.statusCode == 200;
    } catch (e) {
      print('[FCM] Error sending notification: $e');
      return false;
    }
  }


//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////




  static Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing NotificationService...');
    }

    // Request notification permissions
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // For iOS, we need to set up APNS token first
      try {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        // Check if we're on a simulator for APNS handling
        bool isSimulator = false;
        try {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          isSimulator = !deviceInfo.isPhysicalDevice;
          
          if (isSimulator && kDebugMode) {
            print('📱 Running on iOS Simulator - APNS token functionality is limited');
            print('💡 APNS tokens are not available in iOS Simulator - this is expected');
            return; // Skip APNS token attempts in simulator
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not determine device type for APNS: $e');
          }
        }

        // Wait for APNS token with retry mechanism (only on physical devices)
        String? apnsToken;
        int retryCount = 0;
        const maxRetries = 5; // Reduced retries since simulators are handled above
        
        while (apnsToken == null && retryCount < maxRetries) {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            if (kDebugMode) {
              print('🍎 APNS token obtained: $apnsToken');
            }
            break;
          }
          
          retryCount++;
          if (kDebugMode) {
            print('⏳ APNS token not available yet, waiting... (attempt $retryCount/$maxRetries)');
          }
          await Future.delayed(Duration(seconds: retryCount));
        }
        
        if (apnsToken == null) {
          if (kDebugMode) {
            print('⚠️ APNS token still not available after $maxRetries attempts on physical device');
            print('🔍 This indicates APNS configuration issues - check certificates and provisioning');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not get APNS token: $e');
          print('This is normal on iOS simulator or when APNS is not configured');
        }
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidInfo = await _firebaseMessaging.getNotificationSettings();
        if (androidInfo.authorizationStatus != AuthorizationStatus.authorized) {
          await _firebaseMessaging.requestPermission();
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not request Android notification permission: $e');
        }
      }
    } else if (kIsWeb) {
      try {
        await _firebaseMessaging.requestPermission();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not request Web notification permission: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print(
          'ℹ️ No notification permission request needed for this platform.',
        );
      }
    }

    // Local notification init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Chat notifications channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'chat_notifications',
            'Chat Notifications',
            description: 'Notifications for chat messages',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Class reminder notifications channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'class_reminders',
            'Class Reminders',
            description: 'Notifications for upcoming classes',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            enableLights: true,
          ),
        );

        // Class scheduled notifications channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'class_notifications',
            'Class Notifications',
            description: 'Notifications for scheduled classes',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        if (kDebugMode) {
          print('✅ Android notification channels created');
        }
      }
    }

    // Register current FCM token with platform-specific handling
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS-specific FCM token handling
      await _handleiOSFCMToken();
    } else {
      // Android and Web FCM token handling (unchanged)
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) print('🔑 FCM token obtained: $token');
        await _saveTokenToDatabase(token);
      }
    }

    // Token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) print('🔄 FCM token refreshed: $newToken');
      _saveTokenToDatabase(newToken);
    });

    // Message listeners
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Handle notification tap when app is terminated and launched via notification
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationTap(initialMessage);
    }

    if (kDebugMode) {
      print('✅ NotificationService initialized successfully');
    }
  }

  /// Save FCM token to Firestore in an array (supporting multi-login devices)
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      final teacherRef = _firestore.collection('teachers').doc(user.uid);
      final studentRef = _firestore.collection('students').doc(user.uid);
      final adminRef = _firestore.collection('admin').doc(user.uid);

      final teacherDoc = await teacherRef.get();
      final studentDoc = await studentRef.get();
      final adminDoc = await adminRef.get();

      Future<void> updateTokens(
        DocumentReference ref,
        DocumentSnapshot doc,
      ) async {
        List<dynamic> tokens =
            (doc.data() as Map<String, dynamic>?)?['fcmTokens'] ?? [];
        // Remove the token if it already exists to avoid duplicates
        tokens.remove(token);
        // Add the new token to the front
        tokens.insert(0, token);
        // Keep only the 5 most recent tokens
        if (tokens.length > 5) {
          tokens = tokens.sublist(0, 5);
        }
        await ref.set({
          'fcmTokens': tokens,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (teacherDoc.exists) {
        await updateTokens(teacherRef, teacherDoc);
        if (kDebugMode) {
          print('✅ FCM token saved for teacher: ${user.uid}');
        }
        return;
      }

      if (studentDoc.exists) {
        await updateTokens(studentRef, studentDoc);
        if (kDebugMode) {
          print('✅ FCM token saved for student: ${user.uid}');
        }
        return;
      }

      if (adminDoc.exists) {
        await updateTokens(adminRef, adminDoc);
        if (kDebugMode) {
          print('✅ FCM token saved for admin: ${user.uid}');
        }
        return;
      }

      if (kDebugMode) {
        print('⚠️ User not found in any collection (teacher/student/admin): ${user.uid}');
      }
    }
  }

  /// Call this on logout to clean up the current FCM token from Firestore
  static Future<void> removeCurrentToken() async {
    final user = _auth.currentUser;
    final token = await _firebaseMessaging.getToken();
    if (user != null && token != null) {
      final teacherRef = _firestore.collection('teachers').doc(user.uid);
      final studentRef = _firestore.collection('students').doc(user.uid);
      final adminRef = _firestore.collection('admin').doc(user.uid);

      await teacherRef
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          })
          .catchError((_) {});
      await studentRef
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          })
          .catchError((_) {});
      await adminRef
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          })
          .catchError((_) {});
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await _saveNotificationToDatabase(message);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
    await _saveNotificationToDatabase(message);
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final notificationId = message.data['notificationId'] as String?;
    if (notificationId != null) {
      await _markNotificationAsRead(notificationId);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      final notificationId = data['notificationId'] as String?;
      if (notificationId != null) {
        _markNotificationAsRead(notificationId);
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_notifications',
          'Chat Notifications',
          channelDescription: 'Notifications for chat messages',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: json.encode(message.data),
    );
  }

  static Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user != null) {
      final notificationData = {
        'id':
            message.data['notificationId'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'New Message',
        'body': message.notification?.body ?? 'You have a new message',
        'type': message.data['type'] ?? 'chat',
        'senderId': message.data['senderId'] ?? '',
        'senderName': message.data['senderName'] ?? '',
        'chatRoomId': message.data['chatRoomId'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': message.data,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationData['id'])
          .set(notificationData);
    }
  }

  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid ?? '';
      String senderRole = 'unknown';

      final teacherDoc =
          await _firestore.collection('teachers').doc(senderId).get();
      if (teacherDoc.exists) {
        senderRole = 'teacher';
      } else {
        final studentDoc =
            await _firestore.collection('students').doc(senderId).get();
        if (studentDoc.exists) {
          senderRole = 'student';
        }
      }

      if (kDebugMode) {
        print('🔔 sendChatNotification called by $senderRole ($senderId)');
      }

      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New Message from $senderName',
        'body': message,
        'type': 'chat',
        'senderId': senderId,
        'senderName': senderName,
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Save to correct collection and send FCM for background support
      await _saveNotificationToCorrectCollection(receiverId, notificationData);
      
      // Send FCM notification for background support
      await _sendFCMNotificationToUser(
        receiverId, 
        'New Message from $senderName', 
        message,
        extraData: {
          'type': 'chat',
          'chatRoomId': chatRoomId,
          'senderId': senderId,
        }
      );

      if (kDebugMode) {
        print('✅ Chat notification sent to user ($receiverId) with background support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending chat notification: $e');
        print(
          '🔍 Debug Info: receiverId=$receiverId, senderName=$senderName, message=$message, chatRoomId=$chatRoomId,}',
        );
      }
    }
  }

  static Future<void> _markNotificationAsRead(
    String notificationId, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    }
  }

  static Future<void> markNotificationAsRead(
    String notificationId, {
    String? userId,
  }) async {
    await _markNotificationAsRead(notificationId, userId: userId);
  }

  static Future<void> markNotificationAsUnread(
    String notificationId, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': false});
    }
  }

  static Future<void> deleteNotification(
    String notificationId, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    }
  }

  static Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return const Stream.empty();
  }

  static Future<int> getUnreadNotificationCount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .get();
      return snapshot.docs.length;
    }
    return 0;
  }

  static Future<void> refreshFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('🔄 Manually refreshing FCM token: $token');
        }
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing FCM token: $e');
      }
    }
  }

  Future<void> updateClassStatuses() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final classesSnapshot = await firestore.collection('classes').get();
    for (final doc in classesSnapshot.docs) {
      final data = doc.data();
      final date = data['date'];
      final time = data['time'];
      final teacherJoined = data['teacherJoined'] ?? false;
      final studentJoined = data['studentJoined'] ?? false;
      DateTime? classDateTime;
      try {
        final parts = date.split('/');
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final time24 = _parseTimeTo24Hour(time);
          final timeParts = time24.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          classDateTime = DateTime(year, month, day, hour, minute);
        }
      } catch (_) {
        classDateTime = null;
      }
      if (classDateTime == null) continue;
      final endTime = classDateTime.add(const Duration(minutes: 30));
      String newStatus = data['status'] ?? 'upcoming';
      if (now.isBefore(classDateTime)) {
        newStatus = 'upcoming';
      } else if (now.isAfter(classDateTime) && now.isBefore(endTime)) {
        newStatus = 'active';
      } else if (now.isAfter(endTime)) {
        if (teacherJoined || studentJoined) {
          newStatus = 'completed';
        } else {
          newStatus = 'missed';
        }
      }
      if (newStatus != data['status']) {
        await firestore.collection('classes').doc(doc.id).update({
          'status': newStatus,
        });
      }
    }
  }

  String _parseTimeTo24Hour(String time) {
    final timeRegExp = RegExp(r'(\d+):(\d+)\s*([AP]M)', caseSensitive: false);
    final match = timeRegExp.firstMatch(time.trim());
    if (match == null) return time;
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Try to save to teachers collection first
        try {
          final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
          if (teacherDoc.exists) {
            await _firestore.collection('teachers').doc(userId).update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            if (kDebugMode) {
              print('✅ FCM token saved to teachers collection for: $userId');
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Teacher document not found, trying students...');
          }
        }
        
        // Try to save to students collection
        try {
          final studentDoc = await _firestore.collection('students').doc(userId).get();
          if (studentDoc.exists) {
            await _firestore.collection('students').doc(userId).update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            if (kDebugMode) {
              print('✅ FCM token saved to students collection for: $userId');
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Student document not found either');
          }
        }
        
        // If neither collection works, try admin collection
        try {
          final adminDoc = await _firestore.collection('admin').doc(userId).get();
          if (adminDoc.exists) {
            await _firestore.collection('admin').doc(userId).update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            if (kDebugMode) {
              print('✅ FCM token saved to admin collection for: $userId');
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Admin document also not found');
          }
        }
        
        if (kDebugMode) {
          print('❌ No valid collection found for user: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  static Future<void> sendClassScheduledNotification({
    required String receiverId,
    required String teacherName,
    required String classDate,
    required String classTime,
    String? customMessage,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid ?? '';
      final body = customMessage ?? 
          'Your teacher $teacherName has scheduled a class on $classDate at $classTime.';
      
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New Class Scheduled',
        'body': body,
        'type': 'class_scheduled',
        'senderId': senderId,
        'teacherName': teacherName,
        'classDate': classDate,
        'classTime': classTime,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };
      
      // Save in-app notification to correct user collection
      await _saveNotificationToCorrectCollection(receiverId, notificationData);
      
      // Send FCM push notification
      await _sendFCMNotificationToUser(
        receiverId,
        'New Class Scheduled',
        body,
        extraData: {
          'type': 'class_scheduled',
          'teacherName': teacherName,
          'classDate': classDate,
          'classTime': classTime,
        },
      );
      
      if (kDebugMode) {
        print('✅ Class scheduled notification sent successfully to $receiverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending class scheduled notification: $e');
      }
    }
  }

  static Future<void> sendClassReminderNotification({
    required String receiverId,
    String? teacherName,
    String? studentName,
    required String classDate,
    required String classTime,
    bool isMissed = false,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid ?? '';
      final isForTeacher = teacherName == null;
      final missedPrefix = isMissed ? 'MISSED: ' : '';
      final timeDescription = isMissed ? 'was scheduled to start' : 'starts in 5 minutes';
      final title = isMissed ? 'Missed Class Reminder' : '🔔 Class Starting Soon!';
      final body = isForTeacher 
          ? '${missedPrefix}Your class with $studentName $timeDescription! ($classDate at $classTime)'
          : '${missedPrefix}Your class with $teacherName $timeDescription! ($classDate at $classTime)';
      
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'type': 'class_reminder',
        'senderId': senderId,
        'teacherName': teacherName,
        'studentName': studentName,
        'classDate': classDate,
        'classTime': classTime,
        'isMissed': isMissed,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };
      
      // Save to correct collection and send FCM for background support
      await _saveNotificationToCorrectCollection(receiverId, notificationData);
      
      // Show local notification if user is current user (immediate)
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == receiverId) {
        await _showClassReminderLocalNotification(title, body);
      }
      
      // Send FCM notification for background support (critical for when app is closed)
      await _sendFCMNotificationToUser(
        receiverId, 
        title,
        body,
        extraData: {
          'type': 'class_reminder',
          'classDate': classDate,
          'classTime': classTime,
          'isMissed': isMissed.toString(),
        }
      );
      
      if (kDebugMode) {
        print('✅ Class reminder notification sent to user ($receiverId) with background support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending class reminder notification: $e');
      }
    }
  }

  /// Show local notification specifically for class reminders
  static Future<void> _showClassReminderLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'class_reminders',
        'Class Reminders',
        channelDescription: 'Notifications for upcoming classes',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );

      if (kDebugMode) {
        print('✅ Local class reminder notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local class reminder notification: $e');
      }
    }
  }

  /// Helper method to save notifications to the correct collection (teachers/students/admin)
  static Future<void> _saveNotificationToCorrectCollection(String userId, Map<String, dynamic> notificationData) async {
    print('💾 _saveNotificationToCorrectCollection called:');
    print('   userId: $userId');
    print('   notification: ${notificationData['title']} - ${notificationData['body']}');
    
    bool saved = false;
    
    // Try teachers collection first
    try {
      final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
      if (teacherDoc.exists) {
        final teacherData = teacherDoc.data()!;
        print('🎯 Saving to TEACHERS collection:');
        print('   Teacher: ${teacherData['fullName']} (${teacherData['email']})');
        
        await _firestore
            .collection('teachers')
            .doc(userId)
            .collection('notifications')
            .doc(notificationData['id'] as String)
            .set(notificationData);
        saved = true;
        print('✅ Notification saved to teachers collection for: $userId');
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Network issue with teachers collection: $e');
      }
    }
    
    // Try students collection
    if (!saved) {
      try {
        final studentDoc = await _firestore.collection('students').doc(userId).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data()!;
          print('🎯 Saving to STUDENTS collection:');
          print('   Student: ${studentData['fullName']} (${studentData['email']})');
          
          await _firestore
              .collection('students')
              .doc(userId)
              .collection('notifications')
              .doc(notificationData['id'] as String)
              .set(notificationData);
          saved = true;
          print('✅ Notification saved to students collection for: $userId');
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Network issue with students collection: $e');
        }
      }
    }
    
    // Try admin collection
    if (!saved) {
      try {
        final adminDoc = await _firestore.collection('admin').doc(userId).get();
        if (adminDoc.exists) {
          await _firestore
              .collection('admin')
              .doc(userId)
              .collection('notifications')
              .doc(notificationData['id'] as String)
              .set(notificationData);
          saved = true;
          if (kDebugMode) {
            print('✅ Notification saved to admin collection for: $userId');
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Network issue with admin collection: $e');
        }
      }
    }
    
    // Fallback to users collection if all else fails
    if (!saved) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationData['id'] as String)
            .set(notificationData);
        if (kDebugMode) {
          print('✅ Notification saved to fallback users collection for: $userId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Critical error: Could not save notification anywhere for user $userId: $e');
          print('🔍 This indicates a serious network connectivity issue');
        }
      }
    }
  }

  /// Helper method to send FCM notification to a specific user (for background support)
  static Future<void> _sendFCMNotificationToUser(
    String userId, 
    String title, 
    String body, 
    {Map<String, String>? extraData}
  ) async {
    try {
      print('🔍 _sendFCMNotificationToUser called for userId: $userId');
      print('   Title: $title');
      print('   Body: $body');
      
      // Get FCM tokens from the correct collection
      List<String> fcmTokens = [];
      String foundInCollection = '';
      
      // Try teachers collection first
      try {
        final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
        if (teacherDoc.exists) {
          foundInCollection = 'teachers';
          final data = teacherDoc.data()!;
          
          print('🎯 Found user in TEACHERS collection:');
          print('   teacherName: ${data['fullName']}');
          print('   teacherEmail: ${data['email']}');
          
          // Check for multiple tokens (fcmTokens array)
          if (data['fcmTokens'] != null) {
            fcmTokens = List<String>.from(data['fcmTokens']);
          }
          // Fallback to single token (fcmToken)
          else if (data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
            fcmTokens = [data['fcmToken'] as String];
          }
          
          print('   Found ${fcmTokens.length} FCM tokens in teachers collection');
        }
      } catch (e) {
        // Continue to students (might be network issue)
        if (kDebugMode) {
          print('⚠️ Network issue checking teachers collection: $e');
        }
      }
      
      // Try students collection if not found in teachers
      if (fcmTokens.isEmpty) {
        try {
          final studentDoc = await _firestore.collection('students').doc(userId).get();
          if (studentDoc.exists) {
            foundInCollection = 'students';
            final data = studentDoc.data()!;
            
            print('🎯 Found user in STUDENTS collection:');
            print('   studentName: ${data['fullName']}');
            print('   studentEmail: ${data['email']}');
            
            // Check for multiple tokens (fcmTokens array)
            if (data['fcmTokens'] != null) {
              fcmTokens = List<String>.from(data['fcmTokens']);
            }
            // Fallback to single token (fcmToken)
            else if (data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
              fcmTokens = [data['fcmToken'] as String];
            }
            
            print('   Found ${fcmTokens.length} FCM tokens in students collection');
          }
        } catch (e) {
          // Continue to admin (might be network issue)
          if (kDebugMode) {
            print('⚠️ Network issue checking students collection: $e');
          }
        }
      }
      
      // Try admin collection if not found in students
      if (fcmTokens.isEmpty) {
        try {
          final adminDoc = await _firestore.collection('admin').doc(userId).get();
          if (adminDoc.exists) {
            foundInCollection = 'admin';
            final data = adminDoc.data()!;
            
            print('🎯 Found user in ADMIN collection:');
            print('   adminName: ${data['fullName']}');
            print('   adminEmail: ${data['email']}');
            
            // Check for multiple tokens (fcmTokens array)
            if (data['fcmTokens'] != null) {
              fcmTokens = List<String>.from(data['fcmTokens']);
            }
            // Fallback to single token (fcmToken)
            else if (data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
              fcmTokens = [data['fcmToken'] as String];
            }
            
            print('   Found ${fcmTokens.length} FCM tokens in admin collection');
          }
        } catch (e) {
          // Final fallback
          if (kDebugMode) {
            print('⚠️ Network issue checking admin collection: $e');
          }
        }
      }
      
      if (fcmTokens.isNotEmpty) {
        int successCount = 0;
        int totalTokens = fcmTokens.length;
        
        print('📤 Sending FCM notifications to $foundInCollection collection:');
        print('   Total tokens: $totalTokens');
        
        for (final token in fcmTokens) {
          if (token.isNotEmpty) {
            print('   Sending to token: ${token.substring(0, 20)}...');
            final success = await sendFCMNotification(
              title: title,
              body: body,
              token: token,
              data: extraData,
            );
            
            if (success) {
              successCount++;
              print('   ✅ Token send successful');
            } else {
              print('   ❌ Token send failed');
            }
          }
        }
        
        print('📊 FCM Summary: $successCount/$totalTokens successful for user: $userId ($foundInCollection)');
      } else {
        if (kDebugMode) {
          print('⚠️ No FCM tokens found for user: $userId (check network connectivity)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending FCM notification to user $userId: $e');
        print('🔍 This might be due to network connectivity issues - check internet connection');
      }
    }
  }

  /// Helper method to send FCM notification ONLY to admin users (for registration notifications)
  static Future<void> _sendFCMNotificationToAdminOnly(
    String adminUserId, 
    String title, 
    String body, 
    {Map<String, String>? extraData}
  ) async {
    try {
      print('🔍 _sendFCMNotificationToAdminOnly called for adminUserId: $adminUserId');
      print('   Title: $title');
      print('   Body: $body');
      
      // Get FCM tokens ONLY from admin collection
      List<String> fcmTokens = [];
      
      try {
        final adminDoc = await _firestore.collection('admin').doc(adminUserId).get();
        if (adminDoc.exists) {
          final data = adminDoc.data()!;
          
          print('🎯 Found admin in ADMIN collection:');
          print('   adminName: ${data['fullName']}');
          print('   adminEmail: ${data['email']}');
          
          // Check for multiple tokens (fcmTokens array)
          if (data['fcmTokens'] != null) {
            fcmTokens = List<String>.from(data['fcmTokens']);
          }
          // Fallback to single token (fcmToken)
          else if (data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
            fcmTokens = [data['fcmToken'] as String];
          }
          
          print('   Found ${fcmTokens.length} FCM tokens in admin collection');
        } else {
          print('❌ Admin user not found in admin collection: $adminUserId');
          return;
        }
      } catch (e) {
        print('❌ Error checking admin collection: $e');
        return;
      }
      
      if (fcmTokens.isNotEmpty) {
        int successCount = 0;
        int totalTokens = fcmTokens.length;
        
        print('📤 Sending FCM notifications to ADMIN ONLY:');
        print('   Total tokens: $totalTokens');
        
        for (final token in fcmTokens) {
          if (token.isNotEmpty) {
            print('   Sending to admin token: ${token.substring(0, 20)}...');
            final success = await sendFCMNotification(
              title: title,
              body: body,
              token: token,
              data: extraData,
            );
            
            if (success) {
              successCount++;
              print('   ✅ Admin token send successful');
            } else {
              print('   ❌ Admin token send failed');
            }
          }
        }
        
        print('📊 Admin FCM Summary: $successCount/$totalTokens successful for admin: $adminUserId');
      } else {
        print('⚠️ No FCM tokens found for admin: $adminUserId');
      }
    } catch (e) {
      print('❌ Error sending FCM notification to admin $adminUserId: $e');
    }
  }

  // Send notification to admin when a new user registers
  static Future<void> sendNewUserRegisteredNotificationToAdmin({
    required String newUserId,
    required String newUserName,
    required String newUserRole, // "student" or "teacher"
  }) async {
    try {
      print('🔔 sendNewUserRegisteredNotificationToAdmin called:');
      print('   newUserId: $newUserId');
      print('   newUserName: $newUserName');
      print('   newUserRole: $newUserRole');
      
      // Fetch the admin UID from the 'admin' collection (assume only one admin)
      final adminQuery = await _firestore.collection('admin').limit(1).get();
      if (adminQuery.docs.isEmpty) {
        if (kDebugMode) {
          print('❌ No admin found in Firestore.');
        }
        return;
      }
      
      final adminUserId = adminQuery.docs.first.id;
      final adminData = adminQuery.docs.first.data();
      
      print('📧 Found admin:');
      print('   adminUserId: $adminUserId');
      print('   adminEmail: ${adminData['email']}');
      print('   adminName: ${adminData['fullName'] ?? 'Unknown'}');
      
      // SECURITY CHECK: Ensure this admin user is NOT also in teachers or students collection
      // This prevents cross-contamination of notifications
      final teacherCheck = await _firestore.collection('teachers').doc(adminUserId).get();
      final studentCheck = await _firestore.collection('students').doc(adminUserId).get();
      
      if (teacherCheck.exists) {
        print('⚠️ WARNING: Admin user also exists in teachers collection! This could cause notification issues.');
        print('   Teacher data: ${teacherCheck.data()}');
      }
      
      if (studentCheck.exists) {
        print('⚠️ WARNING: Admin user also exists in students collection! This could cause notification issues.');
        print('   Student data: ${studentCheck.data()}');
      }
      
      // Proceed only if this is a pure admin user OR if we want to override the check
      if (!teacherCheck.exists && !studentCheck.exists) {
        print('✅ Verified: Admin user is unique and not in other collections');
      } else {
        print('⚠️ Admin user found in multiple collections - proceeding with caution');
      }
      
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New ${newUserRole.toUpperCase()} Registered',
        'body': '$newUserName has registered as a $newUserRole and needs assignment.',
        'type': 'new_user_registered',
        'userId': newUserId,
        'userName': newUserName,
        'userRole': newUserRole,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };
      
      print('💾 Saving notification to admin collection for adminUserId: $adminUserId');
      
      // Save notification to Firestore using correct collection
      await _saveNotificationToCorrectCollection(adminUserId, notificationData);
      
      print('📤 Sending FCM notification to adminUserId: $adminUserId');
      print('   Title: New ${newUserRole.toUpperCase()} Registered');
      print('   Body: $newUserName has registered as a $newUserRole and needs assignment.');
      
      // Send FCM notification for background support
      await _sendFCMNotificationToAdminOnly(
        adminUserId,
        'New ${newUserRole.toUpperCase()} Registered',
        '$newUserName has registered as a $newUserRole and needs assignment.',
        extraData: {
          'type': 'new_user_registered',
          'userId': newUserId,
          'userName': newUserName,
          'userRole': newUserRole,
        }
      );
      
      print('✅ Registration notification process completed for admin: $adminUserId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending new user registration notification to admin: $e');
      }
    }
  }

  // Send notification to user when they are assigned
  static Future<void> sendUserAssignedNotification({
    required String userId,
    required String assignedName,
    required String assignedRole, // "teacher" or "student"
  }) async {
    try {
      print('🔔 NotificationService.sendUserAssignedNotification called:');
      print('   userId: $userId');
      print('   assignedName: $assignedName');
      print('   assignedRole: $assignedRole');
      print('   Message: "You have been assigned a $assignedRole: $assignedName."');
      
      // SECURITY CHECK: Verify the user type matches the expected role assignment
      if (assignedRole == 'teacher') {
        // This notification should go to a student (student gets assigned a teacher)
        final studentDoc = await _firestore.collection('students').doc(userId).get();
        if (!studentDoc.exists) {
          print('❌ SECURITY ERROR: Trying to send teacher assignment to non-student user: $userId');
          print('   This notification says "You have been assigned a teacher" but user is not in students collection');
          return;
        }
        final studentData = studentDoc.data()!;
        print('✅ Verified: Sending teacher assignment notification to student: ${studentData['fullName']}');
        
      } else if (assignedRole == 'student') {
        // This notification should go to a teacher (teacher gets assigned a student)
        final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
        if (!teacherDoc.exists) {
          print('❌ SECURITY ERROR: Trying to send student assignment to non-teacher user: $userId');
          print('   This notification says "You have been assigned a student" but user is not in teachers collection');
          return;
        }
        final teacherData = teacherDoc.data()!;
        print('✅ Verified: Sending student assignment notification to teacher: ${teacherData['fullName']}');
      }
      
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Assignment Complete',
        'body': 'You have been assigned a $assignedRole: $assignedName.',
        'type': 'assignment',
        'assignedName': assignedName,
        'assignedRole': assignedRole,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };
      
      // Save to correct collection and send FCM for background support
      await _saveNotificationToCorrectCollection(userId, notificationData);
      
      // Send FCM notification for background support
      await _sendFCMNotificationToUser(
        userId,
        'Assignment Complete',
        'You have been assigned a $assignedRole: $assignedName.',
        extraData: {
          'type': 'assignment',
          'assignedName': assignedName,
          'assignedRole': assignedRole,
        }
      );
      
      if (kDebugMode) {
        print('✅ Assignment notification sent to user ($userId) with background support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending assignment notification: $e');
      }
    }
  }

  // Send assignment notifications to both teacher and student
  static Future<void> sendTeacherStudentAssignmentNotifications({
    required String teacherId,
    required String studentId,
    required String teacherName,
    required String studentName,
  }) async {
    try {
      print('🔔 NotificationService.sendTeacherStudentAssignmentNotifications called:');
      print('   teacherId: $teacherId, teacherName: $teacherName');
      print('   studentId: $studentId, studentName: $studentName');
      
      // SECURITY CHECK: Verify user types to prevent cross-contamination
      final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      
      if (!teacherDoc.exists) {
        print('❌ ERROR: Teacher ID $teacherId not found in teachers collection!');
        return;
      }
      
      if (!studentDoc.exists) {
        print('❌ ERROR: Student ID $studentId not found in students collection!');
        return;
      }
      
      print('✅ Verified: Teacher and student exist in correct collections');
      
      // Send notification to student about being assigned a teacher
      await sendStudentAssignmentNotification(
        studentId: studentId,
        teacherName: teacherName,
      );
      
      // Send notification to teacher about being assigned a student
      await sendTeacherAssignmentNotification(
        teacherId: teacherId,
        studentName: studentName,
      );
      
      if (kDebugMode) {
        print('✅ Assignment notifications sent to both teacher and student');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending assignment notifications: $e');
      }
    }
  }

  // Send notification ONLY to student about being assigned a teacher
  static Future<void> sendStudentAssignmentNotification({
    required String studentId,
    required String teacherName,
  }) async {
    try {
      print('📧 Sending STUDENT assignment notification:');
      print('   studentId: $studentId');
      print('   teacherName: $teacherName');
      
      await sendUserAssignedNotification(
        userId: studentId,
        assignedName: teacherName,
        assignedRole: 'teacher',
      );
      
      print('✅ Student assignment notification sent');
    } catch (e) {
      print('❌ Error sending student assignment notification: $e');
    }
  }

  // Send notification ONLY to teacher about being assigned a student
  static Future<void> sendTeacherAssignmentNotification({
    required String teacherId,
    required String studentName,
  }) async {
    try {
      print('📧 Sending TEACHER assignment notification:');
      print('   teacherId: $teacherId');
      print('   studentName: $studentName');
      
      await sendUserAssignedNotification(
        userId: teacherId,
        assignedName: studentName,
        assignedRole: 'student',
      );
      
      print('✅ Teacher assignment notification sent');
    } catch (e) {
      print('❌ Error sending teacher assignment notification: $e');
    }
  }

  /// Removes invalid/expired FCM tokens from all user documents
  static Future<void> _cleanupInvalidToken(String invalidToken) async {
    try {
      // Clean up from teachers collection
      final teachersQuery = await _firestore
          .collection('teachers')
          .where('fcmTokens', arrayContains: invalidToken)
          .get();

      for (var doc in teachersQuery.docs) {
        await doc.reference.update({
          'fcmTokens': FieldValue.arrayRemove([invalidToken]),
        });
        if (kDebugMode) {
          print('🧹 Removed invalid token from teacher: ${doc.id}');
        }
      }

      // Clean up from students collection
      final studentsQuery = await _firestore
          .collection('students')
          .where('fcmTokens', arrayContains: invalidToken)
          .get();

      for (var doc in studentsQuery.docs) {
        await doc.reference.update({
          'fcmTokens': FieldValue.arrayRemove([invalidToken]),
        });
        if (kDebugMode) {
          print('🧹 Removed invalid token from student: ${doc.id}');
        }
      }

      // Clean up from admin collection
      final adminQuery = await _firestore
          .collection('admin')
          .where('fcmTokens', arrayContains: invalidToken)
          .get();

      for (var doc in adminQuery.docs) {
        await doc.reference.update({
          'fcmTokens': FieldValue.arrayRemove([invalidToken]),
        });
        if (kDebugMode) {
          print('🧹 Removed invalid token from admin: ${doc.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up invalid token: $e');
      }
    }
  }

  /// Check network connectivity by attempting to reach Firebase
  static Future<bool> checkNetworkConnectivity() async {
    try {
      // Try a simple read operation to check connectivity
      await _firestore.collection('_connectivity_test').limit(1).get();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🌐 Network connectivity check failed: $e');
        if (e.toString().contains('Unable to resolve host')) {
          print('📶 No internet connection detected');
        }
      }
      return false;
    }
  }

  /// Send a notification with automatic retry and offline handling
  static Future<void> sendNotificationWithRetry({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final notificationData = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'body': body,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          ...?additionalData,
        };

        // Check network connectivity first
        final hasConnection = await checkNetworkConnectivity();
        
        if (!hasConnection) {
          if (kDebugMode) {
            print('⚠️ No network connection - notification will be sent when connection is restored');
          }
          // In a real app, you might want to store this in local storage
          // and retry when connection is restored
          return;
        }

        // Try to save notification
        await _saveNotificationToCorrectCollection(userId, notificationData);
        
        // Try to send FCM notification
        await _sendFCMNotificationToUser(userId, title, body, extraData: {
          'type': type,
          ...?additionalData?.map((k, v) => MapEntry(k, v.toString())),
        });

        if (kDebugMode) {
          print('✅ Notification sent successfully on attempt $attempt');
        }
        return; // Success, exit retry loop

      } catch (e) {
        if (kDebugMode) {
          print('❌ Notification attempt $attempt failed: $e');
        }
        
        if (attempt == maxRetries) {
          if (kDebugMode) {
            print('💥 All $maxRetries notification attempts failed for user: $userId');
          }
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  /// Force refresh and ensure FCM tokens are properly saved for current user
  static Future<void> ensureFCMTokensAreSaved() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user logged in, cannot ensure FCM tokens');
        }
        return;
      }

      // Get fresh FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ Could not get FCM token');
        }
        return;
      }

      if (kDebugMode) {
        print('🔑 Current FCM token: $token');
      }

      // Save using both methods to ensure compatibility
      await _saveTokenToDatabase(token);
      await saveTokenToFirestore(user.uid);

      if (kDebugMode) {
        print('✅ FCM token ensured and saved for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error ensuring FCM tokens: $e');
      }
    }
  }

  /// Test reminder notifications for current user
  static Future<void> testReminderNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user logged in for testing');
        }
        return;
      }

      // First ensure FCM tokens are saved
      await ensureFCMTokensAreSaved();

      // Test sending a reminder notification
      await sendClassReminderNotification(
        receiverId: user.uid,
        teacherName: 'Test Teacher',
        studentName: 'Test Student',
        classDate: '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
        classTime: '${DateTime.now().hour}:${DateTime.now().minute}',
        isMissed: false,
      );

      if (kDebugMode) {
        print('✅ Test reminder notification sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing reminder notifications: $e');
      }
    }
  }

  /// Fix existing pending reminders by adding FCM tokens
  static Future<void> fixExistingReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user logged in');
        }
        return;
      }

      // Get all pending reminders for current user
      final pendingReminders = await _firestore
          .collection('class_reminders')
          .where('status', isEqualTo: 'pending')
          .get();

      if (kDebugMode) {
        print('🔍 Found ${pendingReminders.docs.length} pending reminders to check');
      }

      int fixedCount = 0;
      final batch = _firestore.batch();

      for (final doc in pendingReminders.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String?;
        final teacherId = data['teacherId'] as String?;

        // Check if this reminder involves current user and is missing FCM tokens
        if ((studentId == user.uid || teacherId == user.uid) && 
            (data['studentFcmToken'] == null || data['teacherFcmToken'] == null)) {
          
          String? studentFcmToken;
          String? teacherFcmToken;

          // Get student FCM token
          if (studentId != null) {
            try {
              final studentDoc = await _firestore.collection('students').doc(studentId).get();
              if (studentDoc.exists) {
                studentFcmToken = studentDoc.data()?['fcmToken'] as String?;
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error getting student FCM token: $e');
              }
            }
          }

          // Get teacher FCM token
          if (teacherId != null) {
            try {
              final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
              if (teacherDoc.exists) {
                teacherFcmToken = teacherDoc.data()?['fcmToken'] as String?;
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error getting teacher FCM token: $e');
              }
            }
          }

          // Update the reminder with FCM tokens
          batch.update(doc.reference, {
            'studentFcmToken': studentFcmToken,
            'teacherFcmToken': teacherFcmToken,
            'supportsBackgroundNotification': true,
            'fixedAt': FieldValue.serverTimestamp(),
          });

          fixedCount++;

          if (kDebugMode) {
            print('🔧 Fixed reminder for class ${data['classDate']} ${data['classTime']}');
            print('   👨‍🎓 Student token: ${studentFcmToken != null ? 'Added' : 'Not found'}');
            print('   👨‍🏫 Teacher token: ${teacherFcmToken != null ? 'Added' : 'Not found'}');
          }
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        if (kDebugMode) {
          print('✅ Fixed $fixedCount pending reminders with FCM tokens');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No reminders needed fixing');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fixing existing reminders: $e');
      }
    }
  }

  /// Send a notification when one party joins and is waiting for the other
  static Future<void> sendJoinWaitingNotification({
    required String receiverId,
    required String senderName,
    required String senderRole, // 'student' or 'teacher'
    required String classId,
  }) async {
    String title = 'Join the class please';
    String body = senderRole == 'student'
        ? 'Student $senderName is waiting for you to join the class.'
        : 'Teacher $senderName is waiting for you to join the class.';
    String type = 'join_waiting';

    final notificationData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'type': type,
      'senderName': senderName,
      'senderRole': senderRole,
      'classId': classId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };

    // Save to correct collection and send FCM for background support
    await _saveNotificationToCorrectCollection(receiverId, notificationData);
    await _sendFCMNotificationToUser(
      receiverId,
      title,
      body,
      extraData: {
        'type': type,
        'senderName': senderName,
        'senderRole': senderRole,
        'classId': classId,
      },
    );
  }

  /// Enhanced iOS FCM token handling with simulator support and fallback strategies
  static Future<void> _handleiOSFCMToken() async {
    try {
      // Check if we're on a simulator first
      bool isSimulator = false;
      try {
        // Import device_info_plus if not already imported
        final deviceInfo = await DeviceInfoPlugin().iosInfo;
        isSimulator = !deviceInfo.isPhysicalDevice;
        
        if (isSimulator && kDebugMode) {
          print('📱 Running on iOS Simulator - FCM token functionality is limited');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not determine device type: $e');
        }
      }

      // Add a small delay to ensure APNS token is properly set
      await Future.delayed(const Duration(seconds: 1));
      
      String? token;
      int tokenRetryCount = 0;
      final maxTokenRetries = isSimulator ? 2 : 5; // Fewer retries for simulator
      
      while (token == null && tokenRetryCount < maxTokenRetries) {
        try {
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            if (kDebugMode) print('🔑 FCM token obtained for iOS: $token');
            await _saveTokenToDatabase(token);
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ FCM token request failed (attempt ${tokenRetryCount + 1}): $e');
          }
        }
        
        tokenRetryCount++;
        if (kDebugMode) {
          print('⏳ FCM token not available yet, retrying... (attempt $tokenRetryCount/$maxTokenRetries)');
        }
        
        // Progressive delay, but shorter for simulators
        final delaySeconds = isSimulator ? 1 : tokenRetryCount;
        await Future.delayed(Duration(seconds: delaySeconds));
      }
      
      if (token == null) {
        if (isSimulator) {
          if (kDebugMode) {
            print('📱 FCM token not available on iOS Simulator - this is expected behavior');
            print('💡 To test push notifications, use a physical iOS device');
          }
          
          // Generate a mock token for simulator testing (local notifications only)
          final mockToken = 'simulator_token_${DateTime.now().millisecondsSinceEpoch}';
          if (kDebugMode) {
            print('🔧 Generated mock token for simulator: $mockToken');
          }
          await _saveTokenToDatabase(mockToken);
          
        } else {
          if (kDebugMode) {
            print('⚠️ FCM token is still null on physical iOS device after $maxTokenRetries attempts');
            print('🔍 This might indicate APNS configuration issues or network problems');
            print('💡 Check: 1) APNS certificates 2) Bundle ID 3) Network connectivity');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get FCM token on iOS: $e');
        print('This is normal on iOS simulator or when APNS is not configured');
      }
    }
  }

  /// Validate notification setup and configuration
  static Future<Map<String, dynamic>> validateNotificationSetup() async {
    final results = <String, dynamic>{
      'overall': true,
      'issues': <String>[],
      'warnings': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      // Check Firebase initialization
      try {
        final settings = await _firebaseMessaging.getNotificationSettings();
        results['details']['permissionStatus'] = settings.authorizationStatus.name;
        
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          results['issues'].add('Notification permission not granted');
          results['overall'] = false;
        }
      } catch (e) {
        results['issues'].add('Failed to get notification settings: $e');
        results['overall'] = false;
      }

      // Check FCM token
      try {
        final token = await _firebaseMessaging.getToken();
        results['details']['hasToken'] = token != null;
        results['details']['tokenLength'] = token?.length ?? 0;
        
        if (token == null) {
          results['issues'].add('FCM token is null');
          results['overall'] = false;
        } else if (token.length < 100) {
          results['warnings'].add('FCM token seems unusually short');
        }
      } catch (e) {
        results['issues'].add('Failed to get FCM token: $e');
        results['overall'] = false;
      }

      // Check platform-specific configurations
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          results['details']['hasAPNSToken'] = apnsToken != null;
          
          if (apnsToken == null) {
            results['warnings'].add('APNS token not available (normal on simulator)');
          }
        } catch (e) {
          results['warnings'].add('Could not check APNS token: $e');
        }
      }

      // Check user's token storage
      final user = _auth.currentUser;
      if (user != null) {
        bool foundUser = false;
        
        // Check if user exists in any collection with tokens
        final collections = ['teachers', 'students', 'admin'];
        for (final collection in collections) {
          try {
            final doc = await _firestore.collection(collection).doc(user.uid).get();
            if (doc.exists) {
              foundUser = true;
              final data = doc.data();
              final tokens = data?['fcmTokens'] as List<dynamic>? ?? [];
              
              results['details']['userCollection'] = collection;
              results['details']['tokenCount'] = tokens.length;
              
              if (tokens.isEmpty) {
                results['warnings'].add('User has no FCM tokens stored in Firestore');
              }
              break;
            }
          } catch (e) {
            results['warnings'].add('Error checking $collection: $e');
          }
        }
        
        if (!foundUser) {
          results['issues'].add('User not found in any collection (teachers/students/admin)');
          results['overall'] = false;
        }
      } else {
        results['warnings'].add('No user logged in for token validation');
      }

      // Platform-specific checks
      results['details']['platform'] = defaultTargetPlatform.name;
      results['details']['isWeb'] = kIsWeb;

      if (kDebugMode) {
        print('🔍 Notification setup validation completed');
        print('Overall status: ${results['overall'] ? "✅ PASS" : "❌ FAIL"}');
        if (results['issues'].isNotEmpty) {
          print('Issues found: ${results['issues']}');
        }
        if (results['warnings'].isNotEmpty) {
          print('Warnings: ${results['warnings']}');
        }
      }

    } catch (e) {
      results['issues'].add('Validation failed: $e');
      results['overall'] = false;
    }

    return results;
  }

  /// Get comprehensive notification diagnostics
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
    };

    try {
      // FCM token info
      final token = await _firebaseMessaging.getToken();
      diagnostics['fcmToken'] = {
        'exists': token != null,
        'length': token?.length ?? 0,
        'preview': token?.substring(0, 20) ?? 'null',
      };

      // Permission status
      final settings = await _firebaseMessaging.getNotificationSettings();
      diagnostics['permissions'] = {
        'authorization': settings.authorizationStatus.name,
        'alert': settings.alert.name,
        'badge': settings.badge.name,
        'sound': settings.sound.name,
      };

      // iOS-specific
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        diagnostics['apns'] = {
          'tokenExists': apnsToken != null,
          'tokenLength': apnsToken?.length ?? 0,
        };
      }

      // User info
      final user = _auth.currentUser;
      if (user != null) {
        diagnostics['user'] = {
          'uid': user.uid,
          'email': user.email,
          'isAnonymous': user.isAnonymous,
        };

        // Check user's stored tokens
        final collections = ['teachers', 'students', 'admin'];
        for (final collection in collections) {
          final doc = await _firestore.collection(collection).doc(user.uid).get();
          if (doc.exists) {
            final data = doc.data();
            final tokens = data?['fcmTokens'] as List<dynamic>? ?? [];
            diagnostics['storedTokens'] = {
              'collection': collection,
              'count': tokens.length,
              'tokens': tokens.map((t) => {
                'preview': t.toString().substring(0, 20),
                'length': t.toString().length,
              }).toList(),
            };
            break;
          }
        }
      }

    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }
}
