import 'dart:html' as html;

/// Web implementation for mobile browser detection
class ClassesListWebHelper {
  static bool isMobileBrowser() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') ||
          userAgent.contains('android') ||
          userAgent.contains('iphone') ||
          userAgent.contains('ipad');
    } catch (e) {
      return false;
    }
  }
  
  static String getUserAgent() {
    try {
      return html.window.navigator.userAgent;
    } catch (e) {
      return '';
    }
  }
}
