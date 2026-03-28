import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  static const Set<String> supportedLanguageCodes = {'en', 'ar', 'ur'};

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(String code) {
    if (!supportedLanguageCodes.contains(code)) return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
  }
}
