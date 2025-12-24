import 'package:shared_preferences/shared_preferences.dart';

Future<void> setAdminSessionFlag(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAdminLoggedIn', value);
  
  // Also store timestamp for session tracking
  if (value) {
    await prefs.setString('adminLoginTime', DateTime.now().toIso8601String());
  } else {
    // Clear session data when logging out
    await prefs.remove('adminLoginTime');
    await prefs.remove('adminEmail');
  }
}

Future<bool> getAdminSessionFlag() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isAdminLoggedIn') ?? false;
}

Future<void> setAdminEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('adminEmail', email);
}

Future<String?> getAdminEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('adminEmail');
}

Future<void> clearAdminSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isAdminLoggedIn');
  await prefs.remove('adminLoginTime');
  await prefs.remove('adminEmail');
}

Future<DateTime?> getAdminLoginTime() async {
  final prefs = await SharedPreferences.getInstance();
  final timeString = prefs.getString('adminLoginTime');
  if (timeString != null) {
    return DateTime.parse(timeString);
  }
  return null;
}
