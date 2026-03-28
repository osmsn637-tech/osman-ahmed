import 'app_environment_controller.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.androidVersionMetadataUrl,
    required this.enableNetworkLogging,
  });

  final String apiBaseUrl;
  final String androidVersionMetadataUrl;
  final bool enableNetworkLogging;

  static AppConfig forEnvironment(AppEnvironment environment) {
    return AppConfig(
      apiBaseUrl: environment == AppEnvironment.development
          ? 'https://api.qeu.app'
          : 'https://api.qeu.info',
      androidVersionMetadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
      enableNetworkLogging: true,
    );
  }

  static Future<AppConfig> load({
    AppEnvironment environment = AppEnvironment.production,
  }) async {
    // In a real app this could read from an .env file, remote config, or
    // compile-time flavor. Keeping it synchronous keeps app startup fast.
    return AppConfig.forEnvironment(environment);
  }
}
