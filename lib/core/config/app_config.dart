class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.androidVersionMetadataUrl,
    required this.enableNetworkLogging,
  });

  final String apiBaseUrl;
  final String androidVersionMetadataUrl;
  final bool enableNetworkLogging;

  static Future<AppConfig> load() async {
    // In a real app this could read from an .env file, remote config, or
    // compile-time flavor. Keeping it synchronous keeps app startup fast.
    return const AppConfig(
      apiBaseUrl: 'https://api.qeu.info',
      androidVersionMetadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
      enableNetworkLogging: true,
    );
  }
}
