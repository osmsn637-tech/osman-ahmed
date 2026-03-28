import 'dart:convert';

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
        _normalizeJsonMap(data),
      ),
    );
  }

  Map<String, dynamic> _normalizeJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      return _decodeJsonString(data);
    }

    if (data is List<int>) {
      return _decodeJsonString(utf8.decode(data));
    }

    throw const FormatException('Invalid app update metadata payload');
  }

  Map<String, dynamic> _decodeJsonString(String data) {
    final decoded = jsonDecode(data) as Object?;
    if (decoded is! Map) {
      throw const FormatException('Invalid app update metadata payload');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
