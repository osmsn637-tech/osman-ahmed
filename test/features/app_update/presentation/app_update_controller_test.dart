import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/app_exception.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/app_update/domain/entities/app_update_config.dart';
import 'package:wherehouse/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:wherehouse/features/app_update/domain/services/version_comparator.dart';
import 'package:wherehouse/features/app_update/presentation/controllers/app_update_controller.dart';

void main() {
  test('forces update on Android when installed version is below minimum',
      () async {
    final controller = AppUpdateController(
      repository: const _FakeAppUpdateRepository(
        result: Success<AppUpdateConfig>(
          AppUpdateConfig(
            latestVersion: '1.2.1',
            minSupportedVersion: '1.2.1',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
            releaseNotes: 'Install the latest Android build.',
          ),
        ),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.2.0'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await controller.checkForUpdates();

    expect(controller.state.hasChecked, isTrue);
    expect(controller.state.requiresForceUpdate, isTrue);
    expect(controller.state.installedVersion, '1.2.0');
    expect(controller.state.minimumSupportedVersion, '1.2.1');
  });

  test('does not force update when installed version meets the minimum',
      () async {
    final controller = AppUpdateController(
      repository: const _FakeAppUpdateRepository(
        result: Success<AppUpdateConfig>(
          AppUpdateConfig(
            latestVersion: '1.2.1',
            minSupportedVersion: '1.2.1',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
          ),
        ),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.2.1'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await controller.checkForUpdates();

    expect(controller.state.requiresForceUpdate, isFalse);
  });

  test('never forces update on non-Android platforms', () async {
    final controller = AppUpdateController(
      repository: const _FakeAppUpdateRepository(
        result: Success<AppUpdateConfig>(
          AppUpdateConfig(
            latestVersion: '9.0.0',
            minSupportedVersion: '9.0.0',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
          ),
        ),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: false),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.0.0'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await controller.checkForUpdates();

    expect(controller.state.hasChecked, isTrue);
    expect(controller.state.requiresForceUpdate, isFalse);
  });

  test('fails open when loading remote config fails', () async {
    final controller = AppUpdateController(
      repository: const _FakeAppUpdateRepository(
        result: Failure<AppUpdateConfig>(UnknownException('boom')),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider:
          const _FakeInstalledAppVersionProvider('1.0.0'),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await controller.checkForUpdates();

    expect(controller.state.hasChecked, isTrue);
    expect(controller.state.requiresForceUpdate, isFalse);
  });

  test('fails open when installed version lookup throws', () async {
    final controller = AppUpdateController(
      repository: const _FakeAppUpdateRepository(
        result: Success<AppUpdateConfig>(
          AppUpdateConfig(
            latestVersion: '1.2.1',
            minSupportedVersion: '1.2.1',
            downloadUrl:
                'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
          ),
        ),
      ),
      versionComparator: const VersionComparator(),
      platformInfo: const _FakePlatformInfo(isAndroid: true),
      installedAppVersionProvider: _ThrowingInstalledAppVersionProvider(),
      updateUrlLauncher: _FakeUpdateUrlLauncher(),
    );

    await controller.checkForUpdates();

    expect(controller.state.hasChecked, isTrue);
    expect(controller.state.requiresForceUpdate, isFalse);
  });
}

class _FakeAppUpdateRepository implements AppUpdateRepository {
  const _FakeAppUpdateRepository({required this.result});

  final Result<AppUpdateConfig> result;

  @override
  Future<Result<AppUpdateConfig>> fetchRemoteConfig() async => result;
}

class _FakePlatformInfo implements PlatformInfo {
  const _FakePlatformInfo({required this.isAndroid});

  @override
  final bool isAndroid;
}

class _FakeInstalledAppVersionProvider implements InstalledAppVersionProvider {
  const _FakeInstalledAppVersionProvider(this.version);

  final String version;

  @override
  Future<String> getVersion() async => version;
}

class _FakeUpdateUrlLauncher implements UpdateUrlLauncher {
  @override
  Future<bool> open(String url) async => true;
}

class _ThrowingInstalledAppVersionProvider
    implements InstalledAppVersionProvider {
  @override
  Future<String> getVersion() async {
    throw StateError('version failed');
  }
}
