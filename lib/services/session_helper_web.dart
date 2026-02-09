import 'package:web/web.dart' as web;

Future<void> setAdminSessionFlag(bool value) async {
  web.window.localStorage[' isAdminLoggedIn'] = value ? 'true' : 'false';

  // Also store timestamp for session tracking
  if (value) {
    web.window.localStorage['adminLoginTime'] =
        DateTime.now().toIso8601String();
  } else {
    // Clear session data when logging out
    web.window.localStorage.removeItem('adminLoginTime');
    web.window.localStorage.removeItem('adminEmail');
  }
}

Future<bool> getAdminSessionFlag() async {
  return web.window.localStorage['isAdminLoggedIn'] == 'true';
}

Future<void> setAdminEmail(String email) async {
  web.window.localStorage['adminEmail'] = email;
}

Future<String?> getAdminEmail() async {
  return web.window.localStorage['adminEmail'];
}

Future<void> clearAdminSession() async {
  web.window.localStorage.removeItem('isAdminLoggedIn');
  web.window.localStorage.removeItem('adminLoginTime');
  web.window.localStorage.removeItem('adminEmail');
}

Future<DateTime?> getAdminLoginTime() async {
  final timeString = web.window.localStorage['adminLoginTime'];
  if (timeString != null) {
    return DateTime.parse(timeString);
  }
  return null;
}
