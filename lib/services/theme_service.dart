import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  
  // Private constructor
  ThemeService._();
  
  // Singleton instance
  static final ThemeService _instance = ThemeService._();
  static ThemeService get instance => _instance;
  
  /// Load the saved theme preference from SharedPreferences
  /// Returns ThemeMode.light as default if no preference is saved
  Future<ThemeMode> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      switch (savedTheme) {
        case 'dark':
          return ThemeMode.dark;
        case 'light':
          return ThemeMode.light;
        case 'system':
          return ThemeMode.system;
        default:
          return ThemeMode.light; // Default to light theme
      }
    } catch (e) {
      print('Error loading theme: $e');
      return ThemeMode.light; // Fallback to light theme
    }
  }
  
  /// Save the theme preference to SharedPreferences
  Future<bool> saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      return await prefs.setString(_themeKey, themeString);
    } catch (e) {
      print('Error saving theme: $e');
      return false;
    }
  }
  
  /// Clear the saved theme preference
  Future<bool> clearTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_themeKey);
    } catch (e) {
      print('Error clearing theme: $e');
      return false;
    }
  }
  
  /// Check if a theme preference is saved
  Future<bool> hasThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_themeKey);
    } catch (e) {
      print('Error checking theme preference: $e');
      return false;
    }
  }
}