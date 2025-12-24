import 'dart:html' as html;

Future<void> setAdminSessionFlag(bool value) async {
  html.window.localStorage['isAdminLoggedIn'] = value ? 'true' : 'false';
  
  // Also store timestamp for session tracking
  if (value) {
    html.window.localStorage['adminLoginTime'] = DateTime.now().toIso8601String();
  } else {
    // Clear session data when logging out
    html.window.localStorage.remove('adminLoginTime');
    html.window.localStorage.remove('adminEmail');
  }
}

Future<bool> getAdminSessionFlag() async {
  return html.window.localStorage['isAdminLoggedIn'] == 'true';
}

Future<void> setAdminEmail(String email) async {
  html.window.localStorage['adminEmail'] = email;
}

Future<String?> getAdminEmail() async {
  return html.window.localStorage['adminEmail'];
}

Future<void> clearAdminSession() async {
  html.window.localStorage.remove('isAdminLoggedIn');
  html.window.localStorage.remove('adminLoginTime');
  html.window.localStorage.remove('adminEmail');
}

Future<DateTime?> getAdminLoginTime() async {
  final timeString = html.window.localStorage['adminLoginTime'];
  if (timeString != null) {
    return DateTime.parse(timeString);
  }
  return null;
}
