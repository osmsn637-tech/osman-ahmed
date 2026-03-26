import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_update_controller.dart';

class DefaultPlatformInfo implements PlatformInfo {
  const DefaultPlatformInfo();

  @override
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class PackageInfoInstalledAppVersionProvider
    implements InstalledAppVersionProvider {
  const PackageInfoInstalledAppVersionProvider();

  @override
  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

class UrlLauncherUpdateUrlLauncher implements UpdateUrlLauncher {
  const UrlLauncherUpdateUrlLauncher();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}
