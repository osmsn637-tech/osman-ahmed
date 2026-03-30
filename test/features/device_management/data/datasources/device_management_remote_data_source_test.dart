import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/device_management/data/datasources/device_management_remote_data_source.dart';

void main() {
  test('registerDevice posts the nested device payload', () async {
    final client = _FakeApiClient();
    final dataSource = DeviceManagementRemoteDataSource(client);

    await dataSource.registerDevice(
      deviceId: 'Floor Zebra 07',
      deviceSerial: 'serial-fallback-1',
      model: 'TC21',
      osVersion: '13',
    );

    expect(client.lastPostPath, '/mobile/v1/devices/register');
    expect(client.lastPostData, <String, dynamic>{
      'device': <String, dynamic>{
        'deviceId': 'Floor Zebra 07',
        'deviceSerial': 'serial-fallback-1',
        'model': 'TC21',
        'osVersion': '13',
      },
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio(), const ErrorMapper());

  String lastPostPath = '';
  dynamic lastPostData;

  @override
  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    final payload = <String, dynamic>{'ok': true};
    final parsed = parser != null ? parser(payload) : payload as T;
    return Success<T>(parsed);
  }
}
