class AppUpdateConfig {
  const AppUpdateConfig({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    this.releaseNotes,
  });

  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final String? releaseNotes;
}
