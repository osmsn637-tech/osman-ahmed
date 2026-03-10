import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

class GlobalErrorController extends ChangeNotifier {
  AppException? _error;

  AppException? get error => _error;

  void showError(AppException error) {
    _error = error;
    notifyListeners();
  }

  void clear() {
    _error = null;
    notifyListeners();
  }
}
