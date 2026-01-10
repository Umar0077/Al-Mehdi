import 'dart:async';

import 'package:al_mehdi_online_school/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Service to handle deep linking and app redirection for web platform
/// Redirects mobile browser users to app stores or opens the installed app
class DeepLinkService {
  // Default fallback values (used if Remote Config fails)
  static const String _defaultAndroidPackageName = 'com.almehdi.onlineschool';
  static const String _defaultAndroidScheme = 'almehdi://';
  static const String _defaultIOSScheme = 'almehdi://';

  // Get values from Remote Config or use defaults
  static String get _androidPackageName =>
      RemoteConfigService.instance.androidPackageName.isNotEmpty
          ? RemoteConfigService.instance.androidPackageName
          : _defaultAndroidPackageName;

  static String get _androidAppScheme =>
      RemoteConfigService.instance.deepLinkSchemeAndroid.isNotEmpty
          ? RemoteConfigService.instance.deepLinkSchemeAndroid
          : _defaultAndroidScheme;

  static String get _iosAppScheme =>
      RemoteConfigService.instance.deepLinkSchemeIOS.isNotEmpty
          ? RemoteConfigService.instance.deepLinkSchemeIOS
          : _defaultIOSScheme;

  static String get _playStoreUrl =>
      RemoteConfigService.instance.playStoreUrl.isNotEmpty
          ? RemoteConfigService.instance.playStoreUrl
          : 'https://play.google.com/store/apps/details?id=$_defaultAndroidPackageName';

  static String get _appStoreUrl => RemoteConfigService.instance.appStoreUrl;

  /// Check if the user is on a mobile browser
  static bool _isMobileBrowser() {
    if (!kIsWeb) return false;

    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }

  /// Check if the user is on Android
  static bool _isAndroid() {
    if (!kIsWeb) return false;

    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android');
  }

  /// Check if the user is on iOS
  static bool _isIOS() {
    if (!kIsWeb) return false;

    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }

  /// Initialize deep link handling
  /// Call this method when the web app loads
  /// Make sure to initialize RemoteConfigService before calling this
  static void initialize({
    String? customAndroidScheme,
    String? customIOSScheme,
    String? customPlayStoreUrl,
    String? customAppStoreUrl,
    Duration? timeout,
  }) {
    if (!kIsWeb) return;

    // Check if deep linking is enabled via Remote Config
    if (!RemoteConfigService.instance.isDeepLinkingEnabled) {
      print('DeepLinkService: Deep linking is disabled via Remote Config');
      return;
    }

    // Only proceed if user is on a mobile browser
    if (!_isMobileBrowser()) {
      print('DeepLinkService: User is not on a mobile browser');
      return;
    }

    final androidScheme = customAndroidScheme ?? _androidAppScheme;
    final iosScheme = customIOSScheme ?? _iosAppScheme;
    final playStoreUrl = customPlayStoreUrl ?? _playStoreUrl;
    final appStoreUrl = customAppStoreUrl ?? _appStoreUrl;
    final timeoutDuration =
        timeout ?? RemoteConfigService.instance.deepLinkTimeout;

    print('DeepLinkService: Mobile browser detected');
    print(
      'DeepLinkService: Using timeout: ${timeoutDuration.inMilliseconds}ms',
    );

    if (_isAndroid()) {
      print('DeepLinkService: Android device detected');
      print('DeepLinkService: Play Store URL: $playStoreUrl');
      _handleAndroidRedirect(androidScheme, playStoreUrl, timeoutDuration);
    } else if (_isIOS()) {
      print('DeepLinkService: iOS device detected');
      print('DeepLinkService: App Store URL: $appStoreUrl');
      _handleIOSRedirect(iosScheme, appStoreUrl, timeoutDuration);
    }
  }

  /// Handle Android app redirect
  static void _handleAndroidRedirect(
    String appScheme,
    String playStoreUrl,
    Duration timeout,
  ) {
    // Try to open the app using the custom scheme
    final deepLink = '${appScheme}open';

    // Create a hidden iframe to attempt app launch
    final iframe =
        web.HTMLIFrameElement()
          ..src = deepLink
          ..style.display = 'none';
    web.document.body?.append(iframe);

    // Set a timeout to redirect to Play Store if app doesn't open
    Timer(timeout, () {
      // Check if the page is still visible (app didn't open)
      if (!web.document.hidden) {
        print('DeepLinkService: App not installed, redirecting to Play Store');
        _redirectToStore(playStoreUrl);
      } else {
        print('DeepLinkService: App opened successfully');
      }
      iframe.remove();
    });

    // Alternative method: try intent URL for Android
    Timer(const Duration(milliseconds: 500), () {
      final intentUrl =
          'intent://${appScheme.replaceAll('://', '')}#Intent;'
          'scheme=${appScheme.replaceAll('://', '')};'
          'package=$_androidPackageName;'
          'S.browser_fallback_url=$playStoreUrl;'
          'end';

      // Attempt to open with intent
      try {
        web.window.location.href = intentUrl;
      } catch (e) {
        print('DeepLinkService: Intent redirect failed: $e');
      }
    });
  }

  /// Handle iOS app redirect
  static void _handleIOSRedirect(
    String appScheme,
    String appStoreUrl,
    Duration timeout,
  ) {
    // Try to open the app using the custom scheme
    final deepLink = '${appScheme}open';

    // Record start time
    final startTime = DateTime.now();

    // Attempt to open the app
    try {
      web.window.location.href = deepLink;
    } catch (e) {
      print('DeepLinkService: Deep link failed: $e');
    }

    // Set a timeout to redirect to App Store if app doesn't open
    Timer(timeout, () {
      final elapsedTime = DateTime.now().difference(startTime);

      // If page is still visible and minimal time has passed, app is not installed
      if (!web.document.hidden &&
          elapsedTime < timeout + const Duration(seconds: 1)) {
        print('DeepLinkService: App not installed, redirecting to App Store');
        _redirectToStore(appStoreUrl);
      } else {
        print(
          'DeepLinkService: App opened successfully or user navigated away',
        );
      }
    });
  }

  /// Redirect to app store
  static void _redirectToStore(String storeUrl) {
    try {
      web.window.location.href = storeUrl;
    } catch (e) {
      print('DeepLinkService: Store redirect failed: $e');
    }
  }

  /// Check if app is available with a custom deep link
  static Future<bool> checkAppAvailability(String deepLink) async {
    if (!kIsWeb) return false;

    final completer = Completer<bool>();

    // Try to open the deep link
    final iframe =
        web.HTMLIFrameElement()
          ..src = deepLink
          ..style.display = 'none';
    web.document.body?.append(iframe);

    // Check if app opened after a short delay
    Timer(const Duration(milliseconds: 1000), () {
      final appOpened = web.document.hidden;
      iframe.remove();
      completer.complete(appOpened);
    });

    return completer.future;
  }

  /// Open app with custom path/route
  static void openAppWithRoute({
    required String route,
    String? customAndroidScheme,
    String? customIOSScheme,
  }) {
    if (!kIsWeb || !_isMobileBrowser()) return;

    final androidScheme = customAndroidScheme ?? _androidAppScheme;
    final iosScheme = customIOSScheme ?? _iosAppScheme;

    final scheme = _isAndroid() ? androidScheme : iosScheme;
    final deepLink = '$scheme$route';

    try {
      web.window.location.href = deepLink;
    } catch (e) {
      print('DeepLinkService: Failed to open app with route: $e');
    }
  }

  /// Show a custom prompt to the user
  static void showInstallPrompt({
    required String message,
    required VoidCallback onInstall,
    VoidCallback? onCancel,
  }) {
    if (!kIsWeb) return;

    // Create a simple dialog (you can customize this with your own UI)
    final confirmed = web.window.confirm(message);

    if (confirmed) {
      onInstall();
    } else {
      onCancel?.call();
    }
  }

  /// Get the appropriate store URL for the current platform
  static String? getStoreUrl() {
    if (!kIsWeb || !_isMobileBrowser()) return null;

    if (_isAndroid()) {
      return _playStoreUrl;
    } else if (_isIOS()) {
      return _appStoreUrl;
    }

    return null;
  }
}
