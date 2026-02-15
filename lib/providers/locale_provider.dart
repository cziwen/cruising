import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    if (_locale.languageCode == 'zh') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('zh'));
    }
  }
}
