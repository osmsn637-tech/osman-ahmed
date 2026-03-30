import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/config/app_config.dart';
import 'package:wherehouse/core/config/app_environment_controller.dart';
import 'package:wherehouse/shared/providers/app_providers.dart';

void main() {
  test('development task datasource leaves the task filter unset', () {
    final config = AppConfig.forEnvironment(AppEnvironment.development);

    expect(defaultWorkerTaskTypeFilterForConfig(config), isNull);
  });

  test('production task datasource leaves the task filter unset', () {
    final config = AppConfig.forEnvironment(AppEnvironment.production);

    expect(defaultWorkerTaskTypeFilterForConfig(config), isNull);
  });
}
