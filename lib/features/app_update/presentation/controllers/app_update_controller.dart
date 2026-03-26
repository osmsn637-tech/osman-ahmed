import 'package:flutter/foundation.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../../domain/services/version_comparator.dart';

abstract class PlatformInfo {
  bool get isAndroid;
}

abstract class InstalledAppVersionProvider {
  Future<String> getVersion();
}

abstract class UpdateUrlLauncher {
  Future<bool> open(String url);
}

class AppUpdateState {
  const AppUpdateState({
    this.hasChecked = false,
    this.isChecking = false,
    this.requiresForceUpdate = false,
    this.installedVersion = '',
    this.minimumSupportedVersion = '',
    this.latestVersion = '',
    this.downloadUrl = '',
    this.releaseNotes,
  });

  final bool hasChecked;
  final bool isChecking;
  final bool requiresForceUpdate;
  final String installedVersion;
  final String minimumSupportedVersion;
  final String latestVersion;
  final String downloadUrl;
  final String? releaseNotes;

  AppUpdateState copyWith({
    bool? hasChecked,
    bool? isChecking,
    bool? requiresForceUpdate,
    String? installedVersion,
    String? minimumSupportedVersion,
    String? latestVersion,
    String? downloadUrl,
    String? releaseNotes,
  }) {
    return AppUpdateState(
      hasChecked: hasChecked ?? this.hasChecked,
      isChecking: isChecking ?? this.isChecking,
      requiresForceUpdate: requiresForceUpdate ?? this.requiresForceUpdate,
      installedVersion: installedVersion ?? this.installedVersion,
      minimumSupportedVersion:
          minimumSupportedVersion ?? this.minimumSupportedVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
    );
  }
}

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required AppUpdateRepository repository,
    required VersionComparator versionComparator,
    required PlatformInfo platformInfo,
    required InstalledAppVersionProvider installedAppVersionProvider,
    required UpdateUrlLauncher updateUrlLauncher,
  })  : _repository = repository,
        _versionComparator = versionComparator,
        _platformInfo = platformInfo,
        _installedAppVersionProvider = installedAppVersionProvider,
        _updateUrlLauncher = updateUrlLauncher;

  final AppUpdateRepository _repository;
  final VersionComparator _versionComparator;
  final PlatformInfo _platformInfo;
  final InstalledAppVersionProvider _installedAppVersionProvider;
  final UpdateUrlLauncher _updateUrlLauncher;

  AppUpdateState _state = const AppUpdateState();

  AppUpdateState get state => _state;

  Future<void> checkForUpdates() async {
    if (_state.isChecking) {
      return;
    }

    _state = _state.copyWith(isChecking: true);
    notifyListeners();

    try {
      final installedVersion = await _installedAppVersionProvider.getVersion();

      if (!_platformInfo.isAndroid) {
        _state = _state.copyWith(
          hasChecked: true,
          isChecking: false,
          requiresForceUpdate: false,
          installedVersion: installedVersion,
        );
        notifyListeners();
        return;
      }

      final result = await _repository.fetchRemoteConfig();
      switch (result) {
        case Success<AppUpdateConfig>(:final data):
          _state = _buildResolvedState(
            installedVersion: installedVersion,
            config: data,
          );
        case Failure<AppUpdateConfig>():
          _state = _state.copyWith(
            hasChecked: true,
            isChecking: false,
            requiresForceUpdate: false,
            installedVersion: installedVersion,
          );
      }
    } catch (_) {
      _state = _state.copyWith(
        hasChecked: true,
        isChecking: false,
        requiresForceUpdate: false,
      );
    }
    notifyListeners();
  }

  Future<bool> openUpdate() async {
    if (_state.downloadUrl.isEmpty) {
      return false;
    }
    return _updateUrlLauncher.open(_state.downloadUrl);
  }

  AppUpdateState _buildResolvedState({
    required String installedVersion,
    required AppUpdateConfig config,
  }) {
    return _state.copyWith(
      hasChecked: true,
      isChecking: false,
      requiresForceUpdate: _versionComparator.isBelowMinimum(
        installedVersion,
        config.minSupportedVersion,
      ),
      installedVersion: installedVersion,
      minimumSupportedVersion: config.minSupportedVersion,
      latestVersion: config.latestVersion,
      downloadUrl: config.downloadUrl,
      releaseNotes: config.releaseNotes,
    );
  }
}
