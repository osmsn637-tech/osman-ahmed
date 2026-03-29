import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wherehouse/features/auth/data/models/login_request_dto.dart';

void main() {
  test('login posts to the environment-relative inventory endpoint', () async {
    final client = _FakeApiClient();
    final dataSource = AuthRemoteDataSourceImpl(client);

    await dataSource.login(
      const LoginRequestDto(phone: '0555555555', password: '123456'),
    );

    expect(client.lastPostPath, '/v1/inventory/login');
    expect(
      client.lastPostData,
      <String, dynamic>{
        'country_code': '966',
        'phone': '0555555555',
        'password': '123456',
      },
    );
  });

  test('changePassword posts expected payload to inventory endpoint', () async {
    final client = _FakeApiClient();
    final dataSource = AuthRemoteDataSourceImpl(client);

    await dataSource.changePassword(
      currentPassword: 'old-secret',
      newPassword: 'new-secret',
    );

    expect(client.lastPostPath, '/inventory/change-password');
    expect(
      client.lastPostData,
      <String, dynamic>{
        'currentPassword': 'old-secret',
        'newPassword': 'new-secret',
      },
    );
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
    final payload = path == 'https://api.qeu.info/v1/inventory/login' ||
            path == '/v1/inventory/login'
        ? <String, dynamic>{
            'data': <String, dynamic>{
              'user': <String, dynamic>{
                'id': 'user-1',
                'name': 'Worker',
                'role': 'worker',
                'phone': '0555555555',
                'zone': 'Z01',
              },
              'access_token': 'access-token',
              'refresh_token': 'refresh-token',
            },
          }
        : <String, dynamic>{'ok': true};
    final parsed = parser != null ? parser(payload) : payload as T;
    return Success<T>(parsed);
  }
}
