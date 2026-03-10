import 'package:flutter/foundation.dart';

class GlobalLoadingController extends ChangeNotifier {
  int _counter = 0;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void begin() {
    _counter++;
    _setLoading(true);
  }

  void end() {
    if (_counter == 0) return;
    _counter--;
    if (_counter == 0) {
      _setLoading(false);
    }
  }

  Future<T> track<T>(Future<T> future) async {
    begin();
    try {
      return await future;
    } finally {
      end();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
