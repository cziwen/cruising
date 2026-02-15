import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _localeLanguageCodeKey = 'app_locale_language_code';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_localeLanguageCodeKey);

    if (savedLanguageCode != null && _isSupported(savedLanguageCode)) {
      _locale = Locale(savedLanguageCode);
      return;
    }

    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final systemLanguageCode = systemLocale.languageCode.toLowerCase();
    if (_isSupported(systemLanguageCode)) {
      _locale = Locale(systemLanguageCode);
    } else {
      _locale = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    final languageCode = locale.languageCode.toLowerCase();
    if (!_isSupported(languageCode)) return;
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeLanguageCodeKey, languageCode);
  }

  bool _isSupported(String languageCode) {
    return languageCode == 'en' || languageCode == 'zh';
  }
}
