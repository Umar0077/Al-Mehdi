import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service to manage Firebase Remote Config
/// Handles fetching and caching of remote configuration values
class RemoteConfigService {
  static RemoteConfigService? _instance;
  static FirebaseRemoteConfig? _remoteConfig;

  // Private constructor
  RemoteConfigService._();

  /// Get singleton instance
  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService._();
    return _instance!;
  }

  /// Initialize Firebase Remote Config with default values
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode
                  ? const Duration(minutes: 1) // Shorter interval for debugging
                  : const Duration(hours: 1), // Longer interval for production
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults({
        'ios_app_id': '',
        'android_package_name': 'com.almehdi.onlineschool',
        'deep_link_scheme_android': 'almehdi://',
        'deep_link_scheme_ios': 'almehdi://',
        'play_store_url':
            'https://play.google.com/store/apps/details?id=com.almehdi.onlineschool',
        'app_store_url': 'https://apps.apple.com/app/id',
        'enable_deep_linking': true,
        'deep_link_timeout_ms': 2500,
      });

      // Fetch and activate
      await fetchAndActivate();

      if (kDebugMode) {
        print('RemoteConfigService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Initialization error: $e');
      }
    }
  }

  /// Fetch and activate remote config values
  Future<bool> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig!.fetchAndActivate();
      if (kDebugMode) {
        print(
          'RemoteConfigService: Config ${activated ? "activated" : "already up-to-date"}',
        );
      }
      return activated;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Fetch error: $e');
      }
      return false;
    }
  }

  /// Get iOS App ID for App Store deep linking
  String get iosAppId {
    try {
      return _remoteConfig?.getString('ios_app_id') ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting ios_app_id: $e');
      }
      return '';
    }
  }

  /// Get Android package name
  String get androidPackageName {
    try {
      return _remoteConfig?.getString('android_package_name') ??
          'com.almehdi.onlineschool';
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting android_package_name: $e');
      }
      return 'com.almehdi.onlineschool';
    }
  }

  /// Get Android deep link scheme
  String get deepLinkSchemeAndroid {
    try {
      return _remoteConfig?.getString('deep_link_scheme_android') ??
          'almehdi://';
    } catch (e) {
      if (kDebugMode) {
        print(
          'RemoteConfigService: Error getting deep_link_scheme_android: $e',
        );
      }
      return 'almehdi://';
    }
  }

  /// Get iOS deep link scheme
  String get deepLinkSchemeIOS {
    try {
      return _remoteConfig?.getString('deep_link_scheme_ios') ?? 'almehdi://';
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting deep_link_scheme_ios: $e');
      }
      return 'almehdi://';
    }
  }

  /// Get Play Store URL
  String get playStoreUrl {
    try {
      return _remoteConfig?.getString('play_store_url') ??
          'https://play.google.com/store/apps/details?id=com.almehdi.onlineschool';
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting play_store_url: $e');
      }
      return 'https://play.google.com/store/apps/details?id=com.almehdi.onlineschool';
    }
  }

  /// Get App Store URL (combines base URL with iOS App ID)
  String get appStoreUrl {
    try {
      final baseUrl =
          _remoteConfig?.getString('app_store_url') ??
          'https://apps.apple.com/app/id';
      final appId = iosAppId;
      return appId.isNotEmpty ? '$baseUrl$appId' : baseUrl;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting app_store_url: $e');
      }
      return 'https://apps.apple.com/app/id';
    }
  }

  /// Check if deep linking is enabled
  bool get isDeepLinkingEnabled {
    try {
      return _remoteConfig?.getBool('enable_deep_linking') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting enable_deep_linking: $e');
      }
      return true;
    }
  }

  /// Get deep link timeout in milliseconds
  int get deepLinkTimeoutMs {
    try {
      return _remoteConfig?.getInt('deep_link_timeout_ms') ?? 2500;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting deep_link_timeout_ms: $e');
      }
      return 2500;
    }
  }

  /// Get deep link timeout as Duration
  Duration get deepLinkTimeout {
    return Duration(milliseconds: deepLinkTimeoutMs);
  }

  /// Get a custom string value
  String getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig?.getString(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get a custom boolean value
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig?.getBool(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get a custom integer value
  int getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig?.getInt(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get a custom double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig?.getDouble(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get all config values (for debugging)
  Map<String, dynamic> getAllValues() {
    try {
      final keys = _remoteConfig?.getAll().keys.toList() ?? [];
      final Map<String, dynamic> values = {};

      for (final key in keys) {
        values[key] = _remoteConfig?.getValue(key).asString();
      }

      return values;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfigService: Error getting all values: $e');
      }
      return {};
    }
  }

  /// Print all config values (for debugging)
  void printAllValues() {
    if (kDebugMode) {
      print('RemoteConfigService: Current values:');
      final values = getAllValues();
      values.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }
}
