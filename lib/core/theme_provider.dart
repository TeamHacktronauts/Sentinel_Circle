import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false; // Default to light theme
  bool _isInitialized = false;

  ThemeProvider() {
    _init();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isDarkMode => _isDarkMode;

  Future<void> _init() async {
    await _loadTheme();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
    } catch (e) {
      _isDarkMode = false; // Fallback to light theme
    }
  }

  Future<void> toggleTheme(bool isOn) async {
    if (_isDarkMode == isOn) return;
    
    _isDarkMode = isOn;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Handle error silently
    }
    notifyListeners();
  }
}
