/// Deep Link Service
///
/// This service handles automatic redirection for mobile browser users.
/// When a user opens the web app on a mobile browser, it will:
/// 1. Try to open the installed app using a custom URL scheme
/// 2. If the app is not installed, redirect to the appropriate store (Play Store or App Store)
///
/// Usage:
/// ```dart
/// // In your main.dart or app initialization:
/// DeepLinkService.initialize(
///   customAndroidScheme: 'yourapp://',
///   customIOSScheme: 'yourapp://',
///   customPlayStoreUrl: 'https://play.google.com/store/apps/details?id=com.yourapp',
///   customAppStoreUrl: 'https://apps.apple.com/app/idYOUR_APP_ID',
/// );
/// ```
library;

export 'deep_link_service_web.dart'
    if (dart.library.io) 'deep_link_service_stub.dart';
