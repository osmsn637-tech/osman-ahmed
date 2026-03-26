import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_update_config.dart';
import '../models/app_update_config_model.dart';

abstract class AppUpdateRemoteDataSource {
  Future<Result<AppUpdateConfig>> fetchRemoteConfig();
}

class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSourceImpl(
    this._client, {
    required String metadataUrl,
  }) : _metadataUrl = metadataUrl;

  final ApiClient _client;
  final String _metadataUrl;

  @override
  Future<Result<AppUpdateConfig>> fetchRemoteConfig() {
    return _client.get<AppUpdateConfig>(
      _metadataUrl,
      parser: (data) => AppUpdateConfigModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }
}
