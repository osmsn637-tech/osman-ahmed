import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import 'package:dio/dio.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._client, {String? defaultTaskType})
      : _defaultTaskType = defaultTaskType;

  final ApiClient _client;
  final String? _defaultTaskType;

  Future<Map<String, dynamic>> fetchMyTasks({
    String? taskType,
    String? cursor,
    int pageSize = 400,
  }) async {
    final resolvedTaskType =
        taskType != null && taskType.isNotEmpty ? taskType : _defaultTaskType;
    final response = await _client.get<Map<String, dynamic>>(
      AppEndpoints.workerTasks,
      queryParameters: {
        if (resolvedTaskType != null && resolvedTaskType.isNotEmpty)
          'task_type': resolvedTaskType,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'page_size': pageSize,
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

  Future<void> reportTaskIssue({
    required String taskId,
    required String taskType,
    required String note,
    String? photoPath,
  }) async {
    final trimmedNote = note.trim();
    final trimmedTaskType = taskType.trim();
    final trimmedPhotoPath = photoPath?.trim();
    final response = await _client.post<void>(
      AppEndpoints.workerTaskFlag(taskId),
      data: FormData.fromMap({
        'task_type': trimmedTaskType,
        'note': trimmedNote,
        if (trimmedPhotoPath != null && trimmedPhotoPath.isNotEmpty)
          'photo': await MultipartFile.fromFile(
            trimmedPhotoPath,
            filename: _fileNameFromPath(trimmedPhotoPath),
          ),
      }),
      headers: {'Content-Type': 'multipart/form-data'},
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
    String? locationCode,
    String? targetLocationCode,
    List<Map<String, Object?>>? cycleCountItems,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.workerTaskSubmit(taskId),
      data: {
        'task_type': taskType,
        if (quantity != null) 'quantity': quantity,
        if (locationId.isNotEmpty) 'location_id': locationId,
        if (locationCode != null && locationCode.isNotEmpty)
          'location_code': locationCode,
        if (targetLocationCode != null && targetLocationCode.isNotEmpty)
          'target_location_code': targetLocationCode,
        if (cycleCountItems != null && cycleCountItems.isNotEmpty)
          'items': cycleCountItems,
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

  Future<Map<String, dynamic>> scanAdjustmentLocation({
    required String adjustmentId,
    required String barcode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.adjustmentScanLocation(adjustmentId),
      data: {'barcode': barcode},
      parser: (data) => _asMap(data),
    );
    return response.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> submitAdjustmentCount({
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  }) async {
    final response = await _client.post<void>(
      AppEndpoints.adjustmentItemCount(adjustmentItemId),
      data: {
        'actualQuantity': quantity,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return response.when(
      success: (_) => null,
      failure: (error) => throw error,
    );
  }

  Future<void> finishAdjustment({
    required String adjustmentId,
  }) async {
    final response = await _client.post<void>(
      AppEndpoints.adjustmentFinish(adjustmentId),
      data: const <String, Object?>{},
    );
    return response.when(
      success: (_) => null,
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

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (segments.isEmpty) return 'photo.jpg';
    return segments.last;
  }
}
