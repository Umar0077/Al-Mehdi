/// Stub implementation for non-web platforms
class PlatformDetectorImpl {
  static String getUserAgent() => '';
  static bool matchesMediaQuery(String query) => false;
}
