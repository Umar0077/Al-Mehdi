# Firebase Push Notifications Implementation

This document explains the implementation of Firebase Cloud Messaging (FCM) push notifications for the Al-Mehdi Online School app.

## Features Implemented

### 1. Firebase Cloud Messaging Integration
- Added `firebase_messaging` and `flutter_local_notifications` packages
- Configured Android and iOS notification channels
- Implemented FCM token management

### 2. Notification Service (`lib/services/notification_service.dart`)
- Handles FCM token registration and updates
- Manages local notifications for foreground messages
- Saves notifications to Firestore database
- Provides methods for marking notifications as read/unread
- Handles notification deletion

### 3. Chat Integration
- Updated `ChatService` to send notifications when messages are sent
- Messages are automatically marked as read when chat is opened
- Real-time notification updates

### 4. Notification Screens
- **Student Notifications**: Web and mobile views with filtering and search
- **Teacher Notifications**: Separate notification screens for teachers
- **Features**:
  - Filter by read/unread status
  - Search notifications
  - Mark as read/unread
  - Delete individual notifications
  - Bulk actions (mark all as read, delete all)
  - Real-time statistics

### 5. Android Configuration
- Added core library desugaring for `flutter_local_notifications`
- Configured notification permissions in `AndroidManifest.xml`
- Created notification channel in `MainActivity.kt`
- Added Firebase Cloud Messaging service

### 6. Firebase Cloud Functions
- Created `functions/index.js` to handle push notification sending
- Automatically triggers when notifications are created in Firestore
- Sends push notifications to user's FCM token

## Database Structure

### Notifications Collection
```
users/{userId}/notifications/{notificationId}
{
  id: string,
  title: string,
  body: string,
  type: string, // 'chat', 'class', 'system'
  senderId: string,
  senderName: string,
  chatRoomId: string,
  timestamp: timestamp,
  read: boolean,
  data: object
}
```

### User FCM Tokens
- **Teachers**: `teachers/{teacherId}.fcmToken`
- **Students**: `students/{studentId}.fcmToken`

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Deploy Firebase Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 3. Build and Run
```bash
flutter run
```

## Usage

### For Teachers
1. When a teacher sends a message to a student, the student receives a push notification
2. Students can view notifications in their notification screen
3. Notifications are marked as read when the chat is opened

### For Students
1. When a student sends a message to their teacher, the teacher receives a push notification
2. Teachers can view notifications in their notification screen
3. Notifications are marked as read when the chat is opened

### Notification Management
- **Filter**: View all, read, or unread notifications
- **Search**: Search through notification content
- **Mark as Read/Unread**: Toggle notification status
- **Delete**: Remove individual notifications
- **Bulk Actions**: Mark all as read or delete all notifications

## Technical Details

### Notification Flow
1. User sends a message via `ChatService.sendMessage()`
2. `ChatService` calls `NotificationService.sendChatNotification()`
3. Notification is saved to Firestore
4. Firebase Cloud Function triggers automatically
5. Push notification is sent to receiver's FCM token
6. Local notification is shown if app is in foreground

### Platform Support
- **Android**: Full support with notification channels
- **iOS**: Basic support (requires additional configuration)
- **Web**: Limited support (no push notifications)

## Troubleshooting

### Common Issues
1. **Build Error**: Ensure core library desugaring is enabled in `android/app/build.gradle.kts`
2. **No Notifications**: Check FCM token is properly saved to database
3. **Permission Issues**: Verify notification permissions are granted on device

### Debug Steps
1. Check Firebase Console for function logs
2. Verify FCM tokens are being saved correctly
3. Test with Firebase Console's messaging feature
4. Check device notification settings

## Future Enhancements
- Add notification sound customization
- Implement notification categories
- Add notification scheduling
- Support for rich notifications with images
- Add notification analytics 