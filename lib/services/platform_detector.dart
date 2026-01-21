import 'package:flutter/foundation.dart';

import 'platform_detector_stub.dart'
    if (dart.library.js_interop) 'platform_detector_web.dart';

/// Utility class for detecting platform and browser information
class PlatformDetector {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if the user is on a mobile browser (web only)
  static bool isMobileBrowser() {
    if (!kIsWeb) return false;

    try {
      final userAgent = PlatformDetectorImpl.getUserAgent().toLowerCase();
      return userAgent.contains('android') ||
          userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod') ||
          userAgent.contains('mobile');
    } catch (e) {
      return false;
    }
  }

  /// Check if the user is on Android browser
  static bool isAndroidBrowser() {
    if (!kIsWeb) return false;

    try {
      final userAgent = PlatformDetectorImpl.getUserAgent().toLowerCase();
      return userAgent.contains('android');
    } catch (e) {
      return false;
    }
  }

  /// Check if the user is on iOS browser
  static bool isIOSBrowser() {
    if (!kIsWeb) return false;

    try {
      final userAgent = PlatformDetectorImpl.getUserAgent().toLowerCase();
      return userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  /// Check if the user is on a tablet
  static bool isTablet() {
    if (!kIsWeb) return false;

    try {
      final userAgent = PlatformDetectorImpl.getUserAgent().toLowerCase();
      return userAgent.contains('ipad') || userAgent.contains('tablet');
    } catch (e) {
      return false;
    }
  }

  /// Get the platform name
  static String getPlatformName() {
    if (!kIsWeb) return 'native';

    try {
      final userAgent = PlatformDetectorImpl.getUserAgent().toLowerCase();
      if (userAgent.contains('android')) return 'android';
      if (userAgent.contains('iphone')) return 'iphone';
      if (userAgent.contains('ipad')) return 'ipad';
      if (userAgent.contains('mac')) return 'mac';
      if (userAgent.contains('win')) return 'windows';
      if (userAgent.contains('linux')) return 'linux';
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Check if accessed via PWA (standalone mode)
  static bool isPWA() {
    if (!kIsWeb) return false;

    try {
      return PlatformDetectorImpl.matchesMediaQuery(
        '(display-mode: standalone)',
      );
    } catch (e) {
      return false;
    }
  }

  /// Get user agent string
  static String getUserAgent() {
    if (!kIsWeb) return '';

    try {
      return PlatformDetectorImpl.getUserAgent();
    } catch (e) {
      return '';
    }
  }
}
