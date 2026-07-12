import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currency = 'USD';
  String _fontFamily = 'Default';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currency => _currency;
  String get currencySymbol => _getSymbol(_currency);
  String get fontFamily => _fontFamily;

  ThemeProvider() {
    _loadPreferences();
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeStr = prefs.getString(AppConstants.keyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load currency
    _currency = prefs.getString(AppConstants.keyPrimaryCurrency) ?? AppConstants.defaultCurrency;

    // Load font family
    _fontFamily = prefs.getString(AppConstants.keyAppFont) ?? 'Default';

    notifyListeners();
  }

  // Toggle theme mode and save
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, isDark ? 'dark' : 'light');
  }

  // Update font family and save
  Future<void> updateFontFamily(String fontName) async {
    _fontFamily = fontName;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAppFont, fontName);
  }

  // Update primary currency preference and save
  Future<void> updateCurrency(String newCurrency) async {
    _currency = newCurrency;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPrimaryCurrency, newCurrency);
  }

  String _getSymbol(String code) {
    switch (code) {
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'PKR': return '₨';
      default: return '\$';
    }
  }
}
