import 'package:flutter/material.dart';
import 'package:travel_memories/themes/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppThemes.dark;
  String _themeName = 'dark';

  ThemeData get currentTheme => _currentTheme;
  String get themeName => _themeName;

  void setTheme(String name) {
    switch (name) {
      case 'blue':
        _currentTheme = AppThemes.blue;
        break;
      default:
        _currentTheme = AppThemes.dark;
    }
    _themeName = name;
    notifyListeners();
  }
}