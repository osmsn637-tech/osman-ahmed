import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchMyTasks({
    String? taskType,
    String? cursor,
    int limit = 100,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppEndpoints.workerTasks,
      queryParameters: {
        if (taskType != null && taskType.isNotEmpty) 'task_type': taskType,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
      parser: (data) => _asMap(data),
    );

    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<Map<String, dynamic>> startTask({
    required String taskId,
    required String taskType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.workerTaskStart(taskId),
      data: {'task_type': taskType},
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> skipTask({
    required String taskId,
    required String taskType,
    String? reason,
  }) async {
    final response = await _client.post<void>(
      AppEndpoints.workerTaskSkip(taskId),
      data: {
        'task_type': taskType,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return response.when(
      success: (_) => null,
      failure: (error) => throw error,
    );
  }

  Future<Map<String, dynamic>> submitTask({
    required String taskId,
    required String taskType,
    int? quantity,
    required String locationId,
    String? targetLocationCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.workerTaskSubmit(taskId),
      data: {
        'task_type': taskType,
        if (quantity != null) 'quantity': quantity,
        if (locationId.isNotEmpty) 'location_id': locationId,
        if (targetLocationCode != null && targetLocationCode.isNotEmpty)
          'target_location_code': targetLocationCode,
      },
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<Map<String, dynamic>> getTaskDetail({
    required String taskId,
    required String taskType,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppEndpoints.workerTaskDetail(taskId),
      queryParameters: {'task_type': taskType},
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<Map<String, dynamic>> scanTask({
    required String taskId,
    required String taskType,
    required String barcode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.workerTaskScan(taskId),
      data: {
        'task_type': taskType,
        'barcode': barcode,
      },
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<Map<String, dynamic>> completeTask({
    required String taskId,
    required String taskType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.workerTaskComplete(taskId),
      data: {'task_type': taskType},
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}
