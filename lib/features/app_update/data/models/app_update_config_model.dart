import '../../domain/entities/app_update_config.dart';

class AppUpdateConfigModel extends AppUpdateConfig {
  const AppUpdateConfigModel({
    required super.latestVersion,
    required super.minSupportedVersion,
    required super.downloadUrl,
    super.releaseNotes,
  });

  factory AppUpdateConfigModel.fromJson(Map<String, dynamic> json) {
    final latestVersion = json['latestVersion'];
    final minSupportedVersion = json['minSupportedVersion'];
    final downloadUrl = json['downloadUrl'];
    final releaseNotes = json['releaseNotes'];

    if (latestVersion is! String ||
        minSupportedVersion is! String ||
        downloadUrl is! String) {
      throw const FormatException('Invalid app update metadata');
    }

    return AppUpdateConfigModel(
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes is String ? releaseNotes : null,
    );
  }
}
