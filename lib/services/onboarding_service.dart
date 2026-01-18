import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboardingSeen';
  
  // Private constructor
  OnboardingService._();
  
  // Singleton instance
  static final OnboardingService _instance = OnboardingService._();
  static OnboardingService get instance => _instance;
  
  /// Check if the user has completed onboarding
  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false; // Fallback to showing onboarding if error occurs
    }
  }
  
  /// Mark onboarding as completed
  Future<bool> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      print('Error marking onboarding complete: $e');
      return false;
    }
  }
  
  /// Reset onboarding status (useful for testing or debugging)
  Future<bool> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_onboardingKey);
    } catch (e) {
      print('Error resetting onboarding: $e');
      return false;
    }
  }
}