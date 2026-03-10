import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(String code) {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
  }
}
