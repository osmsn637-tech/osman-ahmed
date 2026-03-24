import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/dashboard/data/datasources/task_remote_data_source.dart';

void main() {
  test('fetchMyTasks sends page_size instead of limit', () async {
    final client = _FakeApiClient();
    final dataSource = TaskRemoteDataSource(client);

    await dataSource.fetchMyTasks(
      taskType: 'cycle_count',
      cursor: 'cursor-2',
      pageSize: 400,
    );

    expect(client.lastPath, '/mobile/v1/worker/tasks');
    expect(client.lastQueryParameters, <String, dynamic>{
      'task_type': 'cycle_count',
      'cursor': 'cursor-2',
      'page_size': 400,
    });
    expect(client.lastQueryParameters.containsKey('limit'), isFalse);
  });

  test('reportTaskIssue posts to the worker task flag endpoint', () async {
    final client = _FakeApiClient();
    final dataSource = TaskRemoteDataSource(client);

    await dataSource.reportTaskIssue(
      taskId: 'task-77',
      note: 'Damaged package',
    );

    expect(client.lastPostPath, '/mobile/v1/worker/tasks/task-77/flag');
    expect(client.lastPostData, isA<FormData>());
    final formData = client.lastPostData! as FormData;
    expect(
      formData.fields.any(
        (field) => field.key == 'note' && field.value == 'Damaged package',
      ),
      isTrue,
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio(), const ErrorMapper());

  String lastPath = '';
  Map<String, dynamic> lastQueryParameters = <String, dynamic>{};
  String lastPostPath = '';
  dynamic lastPostData;

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters ?? <String, dynamic>{};
    final payload = <String, dynamic>{'tasks': <Map<String, dynamic>>[]};
    final parsed = parser != null ? parser(payload) : payload as T;
    return Success<T>(parsed);
  }

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
