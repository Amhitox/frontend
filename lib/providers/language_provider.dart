import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isFrench => _locale.languageCode == 'fr';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      _locale = const Locale('en');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Handle error silently or show a message
      // Error saving language preference
    }
  }

  Future<void> setLanguageFromUser(String? userLang) async {
    if (userLang != null && (userLang == 'en' || userLang == 'fr')) {
      await setLanguage(userLang);
    } else {
      await _loadLanguage();
    }
  }

  String getLanguageName() {
    return isEnglish ? 'English' : 'French';
  }

  String getLanguageCode() {
    return _locale.languageCode;
  }
}
