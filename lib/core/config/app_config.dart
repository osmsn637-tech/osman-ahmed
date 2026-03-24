class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.enableNetworkLogging,
  });

  final String apiBaseUrl;
  final bool enableNetworkLogging;

  static Future<AppConfig> load() async {
    // In a real app this could read from an .env file, remote config, or
    // compile-time flavor. Keeping it synchronous keeps app startup fast.
    return const AppConfig(
      apiBaseUrl: 'https://api.qeu.info',
      enableNetworkLogging: true,
    );
  }
}
