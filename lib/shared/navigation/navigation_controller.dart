import 'package:flutter/foundation.dart';

enum AppTab { home, account }

class NavigationController extends ChangeNotifier {
  AppTab _tab = AppTab.home;

  AppTab get tab => _tab;
  int get index => _tab.index;

  void setTab(AppTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }
}
