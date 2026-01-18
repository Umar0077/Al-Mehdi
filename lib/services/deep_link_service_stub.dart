import 'package:flutter/foundation.dart';

/// Stub implementation for non-web platforms
/// This service only works on web platform
class DeepLinkService {
  static void initialize({
    String? customAndroidScheme,
    String? customIOSScheme,
    String? customPlayStoreUrl,
    String? customAppStoreUrl,
    Duration timeout = const Duration(milliseconds: 2500),
  }) {
    // No-op for non-web platforms
    if (kDebugMode) {
      print('DeepLinkService: This service only works on web platform');
    }
  }

  static Future<bool> checkAppAvailability(String deepLink) async {
    return false;
  }

  static void openAppWithRoute({
    required String route,
    String? customAndroidScheme,
    String? customIOSScheme,
  }) {
    // No-op for non-web platforms
  }

  static void showInstallPrompt({
    required String message,
    required VoidCallback onInstall,
    VoidCallback? onCancel,
  }) {
    // No-op for non-web platforms
  }

  static String? getStoreUrl() {
    return null;
  }
}
