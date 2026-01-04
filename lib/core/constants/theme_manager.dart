import 'package:flutter/material.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeManager() {
    _loadTheme();
  }

  void _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      AppLogger.log('Error loading theme: $e');
      _isDarkMode = false;
      notifyListeners();
    }
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      AppLogger.log('Error saving theme: $e');
    }
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(ConstColors.mainColor),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(ConstColors.mainColor),
      unselectedItemColor: Colors.grey,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(ConstColors.mainColor),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(ConstColors.mainColor),
      unselectedItemColor: Colors.grey,
    ),
  );

  Color getBackgroundColor(BuildContext context) {
    return _isDarkMode ? Color(0xFF121212) : Colors.white;
  }

  Color getCardColor(BuildContext context) {
    return _isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
  }

  Color getTextColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.black;
  }

  Color getSecondaryTextColor(BuildContext context) {
    return _isDarkMode ? Colors.grey[300]! : Colors.grey[600]!;
  }
}
