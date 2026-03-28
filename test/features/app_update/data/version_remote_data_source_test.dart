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

  test('parses github version metadata when the body is a json string',
      () async {
    final client = _FakeApiClient()
      ..responseData = '''
{
  "latestVersion": "1.2.2",
  "minSupportedVersion": "1.2.2",
  "downloadUrl": "https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk",
  "releaseNotes": "Force update to the latest Android build."
}
''';
    final dataSource = AppUpdateRemoteDataSourceImpl(
      client,
      metadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );

    final result = await dataSource.fetchRemoteConfig();

    expect(result, isA<Success<AppUpdateConfig>>());
    final config = (result as Success<AppUpdateConfig>).data;
    expect(config.minSupportedVersion, '1.2.2');
  });

  test('parses github version metadata when the body is utf8 bytes', () async {
    final client = _FakeApiClient()
      ..responseData = <int>[
        123,
        34,
        108,
        97,
        116,
        101,
        115,
        116,
        86,
        101,
        114,
        115,
        105,
        111,
        110,
        34,
        58,
        34,
        49,
        46,
        50,
        46,
        50,
        34,
        44,
        34,
        109,
        105,
        110,
        83,
        117,
        112,
        112,
        111,
        114,
        116,
        101,
        100,
        86,
        101,
        114,
        115,
        105,
        111,
        110,
        34,
        58,
        34,
        49,
        46,
        50,
        46,
        50,
        34,
        44,
        34,
        100,
        111,
        119,
        110,
        108,
        111,
        97,
        100,
        85,
        114,
        108,
        34,
        58,
        34,
        104,
        116,
        116,
        112,
        115,
        58,
        47,
        47,
        103,
        105,
        116,
        104,
        117,
        98,
        46,
        99,
        111,
        109,
        47,
        111,
        115,
        109,
        115,
        110,
        54,
        51,
        55,
        45,
        116,
        101,
        99,
        104,
        47,
        111,
        115,
        109,
        97,
        110,
        45,
        97,
        104,
        109,
        101,
        100,
        47,
        114,
        101,
        108,
        101,
        97,
        115,
        101,
        115,
        47,
        100,
        111,
        119,
        110,
        108,
        111,
        97,
        100,
        47,
        112,
        117,
        116,
        97,
        119,
        97,
        121,
        47,
        112,
        117,
        116,
        97,
        119,
        97,
        121,
        95,
        97,
        112,
        112,
        46,
        97,
        112,
        107,
        34,
        44,
        34,
        114,
        101,
        108,
        101,
        97,
        115,
        101,
        78,
        111,
        116,
        101,
        115,
        34,
        58,
        34,
        70,
        111,
        114,
        99,
        101,
        32,
        117,
        112,
        100,
        97,
        116,
        101,
        32,
        116,
        111,
        32,
        116,
        104,
        101,
        32,
        108,
        97,
        116,
        101,
        115,
        116,
        32,
        65,
        110,
        100,
        114,
        111,
        105,
        100,
        32,
        98,
        117,
        105,
        108,
        100,
        46,
        34,
        125,
      ];
    final dataSource = AppUpdateRemoteDataSourceImpl(
      client,
      metadataUrl:
          'https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/version.json',
    );

    final result = await dataSource.fetchRemoteConfig();

    expect(result, isA<Success<AppUpdateConfig>>());
    final config = (result as Success<AppUpdateConfig>).data;
    expect(config.latestVersion, '1.2.2');
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
