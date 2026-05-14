import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'ur'; // default

  String get currentLanguage => _currentLanguage;
  bool get isUrdu => _currentLanguage == 'ur';
  bool get isEnglish => _currentLanguage == 'en';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString('language');
    if (stored == 'urdu') stored = 'ur';
    if (stored == 'english') stored = 'en';
    _currentLanguage = stored ?? 'ur';
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'ur' ? 'en' : 'ur';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }
}