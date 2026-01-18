import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Get user's country from their IP address
  /// Returns country name (e.g., "Pakistan", "United States")
  /// Returns null if detection fails
  static Future<String?> getCountryFromIP() async {
    try {
      // Using ip-api.com - free, no API key required
      // Note: HTTPS is available for paid plans, but HTTP works fine for this use case
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/?fields=country'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['country'] as String?;
      }
      return null;
    } catch (e) {
      // Silent fail - don't disrupt user experience
      if (kDebugMode) {
        print('⚠️ Failed to detect country from IP: $e');
      }
      return null;
    }
  }
}
