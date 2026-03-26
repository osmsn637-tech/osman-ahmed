import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/app_update/data/datasources/app_update_remote_data_source.dart';
import 'package:wherehouse/features/app_update/domain/entities/app_update_config.dart';

void main() {
  test('fetches the raw github version file and parses update metadata',
      () async {
    final client = _FakeApiClient()
      ..responseData = <String, dynamic>{
        'latestVersion': '1.2.1',
        'minSupportedVersion': '1.2.1',
        'downloadUrl':
            'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
        'releaseNotes': 'Force update to the latest Android build.',
      };
    final dataSource = AppUpdateRemoteDataSourceImpl(
      client,
      metadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );

    final result = await dataSource.fetchRemoteConfig();

    expect(
      client.lastGetPath,
      'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );
    expect(result, isA<Success<AppUpdateConfig>>());
    final config = (result as Success<AppUpdateConfig>).data;
    expect(config.latestVersion, '1.2.1');
    expect(config.minSupportedVersion, '1.2.1');
    expect(
      config.downloadUrl,
      'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk',
    );
    expect(config.releaseNotes, 'Force update to the latest Android build.');
  });

  test('returns failure when required fields are missing', () async {
    final client = _FakeApiClient()
      ..responseData = <String, dynamic>{
        'latestVersion': '1.2.1',
      };
    final dataSource = AppUpdateRemoteDataSourceImpl(
      client,
      metadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );

    final result = await dataSource.fetchRemoteConfig();

    expect(result, isA<Failure<AppUpdateConfig>>());
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio(), const ErrorMapper());

  String lastGetPath = '';
  dynamic responseData = const <String, dynamic>{};

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    lastGetPath = path;
    try {
      final parsed = parser != null ? parser(responseData) : responseData as T;
      return Success<T>(parsed);
    } catch (error) {
      return Failure<T>(const ErrorMapper().map(error));
    }
  }
}
