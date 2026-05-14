import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './translations.dart'; // Jahan Claude wala translations code hai

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'english'; // Default language

  String get currentLanguage => _currentLanguage;

  // Constructor: App khulte hi purani pasand check karega
  LanguageProvider() {
    _loadLanguage();
  }

  // Language toggle karne ka function
  void toggleLanguage() async {
    _currentLanguage = (_currentLanguage == 'english') ? 'urdu' : 'english';

    // Save setting so app remembers next time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);

    notifyListeners(); // Poori app ko batata hai ke text change karo!
  }

  // Purani setting load karna
  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'english';
    notifyListeners();
  }

  // Translation hasil karne ka asaan shortcut
  String translate(String key) {
    return Translations.t(key, _currentLanguage);
  }
}