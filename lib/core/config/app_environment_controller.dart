import 'package:flutter/foundation.dart';

import '../storage/secure_token_storage.dart';
import 'app_config.dart';

enum AppEnvironment {
  production('production'),
  development('development');

  const AppEnvironment(this.storageValue);

  final String storageValue;

  static AppEnvironment fromStorageValue(String? value) {
    return switch (value) {
      'development' => AppEnvironment.development,
      _ => AppEnvironment.production,
    };
  }
}

class AppEnvironmentController extends ChangeNotifier {
  AppEnvironmentController({
    SecureTokenStorage? storage,
    AppEnvironment initialEnvironment = AppEnvironment.production,
  })  : _storage = storage ?? SecureTokenStorage(),
        _environment = initialEnvironment;

  final SecureTokenStorage _storage;
  AppEnvironment _environment;

  AppEnvironment get environment => _environment;
  bool get isDevelopment => _environment == AppEnvironment.development;
  AppConfig get config => AppConfig.forEnvironment(_environment);

  Future<void> load() async {
    final storedValue = await _storage.readAppEnvironment();
    _environment = AppEnvironment.fromStorageValue(storedValue);
    notifyListeners();
  }

  Future<void> toggleEnvironment() async {
    _environment = _environment == AppEnvironment.production
        ? AppEnvironment.development
        : AppEnvironment.production;
    await _storage.persistAppEnvironment(_environment.storageValue);
    await _storage.clear();
    notifyListeners();
  }
}
