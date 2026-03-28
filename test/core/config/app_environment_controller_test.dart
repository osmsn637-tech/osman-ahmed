import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/config/app_environment_controller.dart';
import 'package:wherehouse/core/storage/secure_token_storage.dart';

void main() {
  test('app environment controller defaults to production config', () async {
    final storage = _FakeSecureTokenStorage();
    final controller = AppEnvironmentController(storage: storage);

    await controller.load();

    expect(controller.environment, AppEnvironment.production);
    expect(controller.config.apiBaseUrl, 'https://api.qeu.info');
    expect(controller.isDevelopment, isFalse);
  });

  test('app environment controller restores persisted development mode',
      () async {
    final storage = _FakeSecureTokenStorage(
      environmentValue: AppEnvironment.development.storageValue,
    );
    final controller = AppEnvironmentController(storage: storage);

    await controller.load();

    expect(controller.environment, AppEnvironment.development);
    expect(controller.config.apiBaseUrl, 'https://api.qeu.app');
    expect(controller.isDevelopment, isTrue);
  });

  test('app environment controller persists toggles and clears auth state',
      () async {
    final storage = _FakeSecureTokenStorage();
    final controller = AppEnvironmentController(storage: storage);

    await controller.load();
    await controller.toggleEnvironment();

    expect(controller.environment, AppEnvironment.development);
    expect(controller.config.apiBaseUrl, 'https://api.qeu.app');
    expect(storage.environmentValue, AppEnvironment.development.storageValue);
    expect(storage.clearCalls, 1);
  });
}

class _FakeSecureTokenStorage extends SecureTokenStorage {
  _FakeSecureTokenStorage({this.environmentValue});

  String? environmentValue;
  int clearCalls = 0;

  @override
  Future<String?> readAppEnvironment() async => environmentValue;

  @override
  Future<void> persistAppEnvironment(String value) async {
    environmentValue = value;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
  }
}
