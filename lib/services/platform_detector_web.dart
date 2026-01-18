import 'package:web/web.dart' as web;

/// Web implementation for platform detection
class PlatformDetectorImpl {
  static String getUserAgent() {
    return web.window.navigator.userAgent;
  }

  static bool matchesMediaQuery(String query) {
    return web.window.matchMedia(query).matches;
  }
}
