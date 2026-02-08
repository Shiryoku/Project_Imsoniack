import 'package:flutter/material.dart';

class ThemeManager extends ValueNotifier<ThemeMode> {
  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();
  
  factory ThemeManager() {
    return _instance;
  }

  ThemeManager._internal() : super(ThemeMode.light);

  void toggleTheme(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
  
  bool get isDarkMode => value == ThemeMode.dark;
}
