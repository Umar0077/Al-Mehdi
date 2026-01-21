import 'package:web/web.dart' as web;

/// Web implementation for mobile redirect web operations
class MobileRedirectWebHelper {
  static String getUserAgent() {
    return web.window.navigator.userAgent;
  }

  static void setLocationHref(String url) {
    web.window.location.href = url;
  }

  static void openWindow(String url, String target) {
    web.window.open(url, target);
  }
}
