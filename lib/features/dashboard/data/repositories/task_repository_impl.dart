import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/exception_entity.dart';
import '../../domain/entities/ai_alert_entity.dart';
import '../../domain/entities/adjustment_task_entities.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../../domain/entities/task_entity.dart';
import '../../../../core/errors/app_exception.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dashboardRemoteDataSource, this._taskRemoteDataSource);

  final DashboardRemoteDataSource _dashboardRemoteDataSource;
  final TaskRemoteDataSource _taskRemoteDataSource;
  final Map<int, TaskEntity> _localTasks = {};
  final Map<int, String> _claimedTasks = {};
  final Map<String, int> _tasksBySourceEventId = {};
  final Map<String, int> _taskIdsByFingerprint = {};
  int _nextLocalTaskId = -1;

  @override
  Future<DashboardSummaryEntity> getDashboardSummary() async {
    try {
      return await _dashboardRemoteDataSource.fetchSummary();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<ExceptionEntity>> getExceptions() async {
    try {
      return await _dashboardRemoteDataSource.fetchExceptions();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> resolveException({required int id, required String action}) async {
    try {
      await _dashboardRemoteDataSource.resolveException(id: id, action: action);
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<AiAlertEntity>> getAiAlerts() async {
    try {
      return await _dashboardRemoteDataSource.fetchAiAlerts();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<TaskEntity>> getTasksForZone(String zone) async {
    try {
      final remote = await _taskRemoteDataSource.fetchMyTasks();
      final remoteTasks = _parseTaskCollection(remote);
      _cacheRemoteTasks(remoteTasks);
      final normalizedZone = _normalizeZone(zone);
      for (final task in remoteTasks) {
        final cached = _localTasks[task.id] ?? task;
        _localTasks[task.id] = cached;
      }

      return remoteTasks
          .map((task) => _withClaim(_localTasks[task.id] ?? task))
          .where((task) => _matchesRequestedZone(task, normalizedZone))
          .toList();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) async {
    final tasks = await getTasksForZone('');
    return tasks.where((t) => t.assignedTo == workerId).toList();
  }

  @override
  Future<TaskEntity?> findBySourceEventId(String sourceEventId) async {
    final localMatch = _tasksBySourceEventId[sourceEventId];
    if (localMatch != null) {
      return _localTasks[localMatch] ?? await _findTaskInRemoteById(localMatch);
    }

    final allTasks = await getTasksForZone('');
    for (final task in allTasks) {
      if (task.sourceEventId == sourceEventId) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<TaskEntity> completeTask(
    int taskId, {
    int? quantity,
    String? locationId,
  }) async {
    final resolved = await _resolveTask(taskId);
    if (resolved == null) {
      throw ValidationException('Task $taskId not found');
    }

    final remoteTaskId = _remoteTaskIdFor(resolved);
    final taskType = _workerTaskType(resolved);
    final targetQuantity = quantity == null || quantity <= 0 ? resolved.quantity : quantity;
    final targetLocation = (locationId ?? resolved.toLocation ?? '').trim();
    final targetLocationId = (locationId ?? resolved.toLocationId ?? targetLocation).trim();

    if (resolved.type == TaskType.adjustment) {
      await _taskRemoteDataSource.finishAdjustment(
        adjustmentId: remoteTaskId,
      );
    } else if (taskType == 'receiving' ||
        taskType == 'return' ||
        taskType == 'cycle_count') {
      await _taskRemoteDataSource.completeTask(
        taskId: remoteTaskId,
        taskType: taskType,
      );
    } else {
      await _taskRemoteDataSource.submitTask(
        taskId: remoteTaskId,
        taskType: taskType,
        quantity: targetQuantity,
        locationId: resolved.type == TaskType.refill ? '' : targetLocationId,
        targetLocationCode: resolved.type == TaskType.refill ? targetLocation : null,
      );
    }
    final completed = _cloneTask(task: resolved, status: TaskStatus.completed);
    _localTasks[completed.id] = completed;
    return completed;
  }

  @override
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    final existing = await _resolveTask(taskId);
    if (existing == null) {
      throw ValidationException('Task $taskId not found');
    }

    final workflowData = Map<String, Object?>.from(existing.workflowData)
      ..['cycleCountProgress'] = progress;
    final updated = _cloneTask(task: existing, workflowData: workflowData);
    _localTasks[updated.id] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> claimTask({required int taskId, required String workerId}) async {
    final existing = await _resolveTask(taskId);
    if (existing == null) {
      throw ValidationException(
        'Task $taskId cannot be claimed because it was not found.',
      );
    }
    await _taskRemoteDataSource.startTask(
      taskId: _remoteTaskIdFor(existing),
      taskType: _workerTaskType(existing),
    );
    _claimedTasks[taskId] = workerId;

    final claimed = _cloneTask(
      task: existing,
      assignedTo: workerId,
      status: TaskStatus.inProgress,
    );
    _localTasks[claimed.id] = claimed;
    return claimed;
  }

  @override
  Future<Map<String, dynamic>> suggestTask(int taskId) async {
    final task = await _resolveTask(taskId);
    if (task == null) {
      throw ValidationException('Task $taskId not found');
    }
    final location = task.toLocation?.trim();
    if (location == null || location.isEmpty) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{
      'locationCode': location,
      'location_id': task.toLocationId ?? location,
      'toLocation': location,
    };
  }

  @override
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  }) async {
    try {
      final task = await _resolveTask(taskId);
      if (task == null) {
        throw ValidationException('Task $taskId not found');
      }
      return await _taskRemoteDataSource.scanTask(
        taskId: _remoteTaskIdFor(task),
        taskType: _workerTaskType(task),
        barcode: barcode,
      );
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation({
    required int taskId,
    required String barcode,
  }) async {
    final task = await _resolveTask(taskId);
    if (task == null) {
      throw ValidationException('Task $taskId not found');
    }
    if (task.type != TaskType.adjustment) {
      throw ValidationException('Task $taskId is not an adjustment task');
    }

    final response = await _taskRemoteDataSource.scanAdjustmentLocation(
      adjustmentId: _remoteTaskIdFor(task),
      barcode: barcode,
    );
    return AdjustmentTaskLocationScan.fromMap(response);
  }

  @override
  Future<void> submitAdjustmentCount({
    required int taskId,
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  }) async {
    final task = await _resolveTask(taskId);
    if (task == null) {
      throw ValidationException('Task $taskId not found');
    }
    if (task.type != TaskType.adjustment) {
      throw ValidationException('Task $taskId is not an adjustment task');
    }

    await _taskRemoteDataSource.submitAdjustmentCount(
      adjustmentItemId: adjustmentItemId,
      actualQuantity: actualQuantity,
      notes: notes,
    );
  }

  @override
  Future<QuickAdjustmentResult> createQuickAdjustment({
    required String warehouseId,
    required int productId,
    required String locationId,
    required int systemQuantity,
    required int actualQuantity,
    String? reason,
    String? notes,
    String? batchNumber,
    String? expiryDate,
  }) async {
    try {
      final response = await _taskRemoteDataSource.createQuickAdjustment(
        warehouseId: warehouseId,
        productId: productId,
        locationId: locationId,
        systemQuantity: systemQuantity,
        actualQuantity: actualQuantity,
        reason: reason,
        notes: notes,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
      );
      return QuickAdjustmentResult.fromJson(response);
    } catch (error) {
      return Future.error(error);
    }
  }

  TaskEntity _withClaim(TaskEntity task) {
    final assignedWorker = _claimedTasks[task.id];
    if (assignedWorker == null) return task;
    if (task.assignedTo == assignedWorker) return task;

    return _cloneTask(
      task: task,
      assignedTo: assignedWorker,
      status: task.isCompleted ? task.status : TaskStatus.inProgress,
    );
  }

  List<TaskEntity> _parseTaskCollection(Map<String, dynamic> payload) {
    final tasks = payload['tasks'];
    if (tasks is! List) return const <TaskEntity>[];

    final list = <TaskEntity>[];
    for (final item in tasks) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);
      final unifiedTask = _parseUnifiedTask(data);
      if (unifiedTask != null) {
        list.add(unifiedTask);
        continue;
      }
      final toLocation = _asString(_firstNonNull([
        data['toLocation'],
        data['to_location'],
        data['suggestedZone'],
        data['suggested_zone'],
        data['zone'],
        data['zoneCode'],
        data['zone_code'],
      ]));
      final fromLocation = _asString(_firstNonNull([
        data['fromLocation'],
        data['from_location'],
      ]));
      final product = _asMap(data['product']) ?? _asMap(data['item']);
      final rawType = _asString(_firstNonNull([
        data['taskType'],
        data['task_type'],
        data['type'],
        data['taskCode'],
        data['task_code'],
        data['operationType'],
        data['operation_type'],
      ]));
      final itemId = _toInt(_firstNonNull([
            data['itemId'],
            data['item_id'],
            data['productId'],
            data['product_id'],
            product?['item_id'],
            product?['id'],
            product?['productId'],
            product?['product_id'],
          ])) ??
          0;
      final itemName = _asString(_firstNonNull([
            data['productName'],
            data['product_name'],
            data['itemName'],
            data['item_name'],
            data['name'],
            product?['productName'],
            product?['product_name'],
            product?['itemName'],
            product?['item_name'],
            product?['name'],
          ])) ??
          'Unknown item';
      final itemBarcode = _asString(_firstNonNull([
        data['product_barcode'],
        product?['product_barcode'],
        data['receiptNumber'],
        data['receipt_number'],
        data['barcode'],
        data['itemBarcode'],
        data['item_barcode'],
        product?['barcode'],
      ]));
      final quantity = _toInt(data['quantity']) ?? 0;
      final sourceEventId = _asString(_firstNonNull([
        data['sourceEventId'],
        data['source_event_id'],
      ]));
      final id = _toInt(_firstNonNull([data['taskId'], data['id'], data['task_id']])) ??
          _stableLocalIdForRemoteTask(
            remoteTaskId: _asString(_firstNonNull([data['taskId'], data['id'], data['task_id']])),
            sourceEventId: sourceEventId,
            rawType: rawType,
            itemId: itemId,
            itemName: itemName,
            itemBarcode: itemBarcode,
            fromLocation: fromLocation,
            toLocation: toLocation,
            quantity: quantity,
          );
      final zone = _normalizeZone(toLocation) ?? 'Z01';
      list.add(
        TaskEntity(
          id: id,
          remoteTaskId: _asString(_firstNonNull([data['taskId'], data['id'], data['task_id']])),
          apiTaskType: rawType,
          type: _toTaskType(rawType),
          itemId: itemId,
          itemName: itemName,
          itemBarcode: itemBarcode,
          itemImageUrl: _normalizeImageUrl(_asString(_firstNonNull([
            data['productImage'],
            data['product_image'],
            data['item_image_url'],
            data['item_image'],
            data['itemImageUrl'],
            data['image_url'],
            data['imageUrl'],
            product?['productImage'],
            product?['product_image'],
            product?['image_url'],
            product?['imageUrl'],
            product?['item_image'],
            product?['item_image_url'],
            product?['itemImageUrl'],
          ]))),
          fromLocation: fromLocation,
          toLocation: toLocation,
          toLocationId: null,
          quantity: quantity,
          assignedTo: null,
          status: _toTaskStatus(_asString(data['status'])),
          createdBy: _asString(data['createdBy']) ??
              _asString(data['created_by']) ??
              'system',
          zone: zone,
          createdAt: DateTime.now(),
          source: TaskSource.inbound,
          priority: TaskPriority.medium,
          sourceEventId: sourceEventId,
        ),
      );
    }
    return list;
  }

  Future<TaskEntity?> _findTaskInRemoteById(int taskId) async {
    final local = _localTasks[taskId];
    if (local != null) return local;

    final remote = await _taskRemoteDataSource.fetchMyTasks();
    final parsed = _parseTaskCollection(remote);
    _cacheRemoteTasks(parsed);
    for (final task in parsed) {
      final maybe = _withClaim(task);
      if (maybe.id == taskId) {
        return maybe;
      }
    }
    return _localTasks[taskId];
  }

  Future<TaskEntity?> _resolveTask(int taskId) async {
    return _localTasks[taskId] ?? await _findTaskInRemoteById(taskId);
  }

  void _cacheRemoteTasks(List<TaskEntity> tasks) {
    for (final task in tasks) {
      _localTasks.putIfAbsent(task.id, () => task);
      if (task.sourceEventId != null) {
        _tasksBySourceEventId.putIfAbsent(task.sourceEventId!, () => task.id);
      }
    }
  }

  int _stableLocalIdForRemoteTask({
    required String? remoteTaskId,
    required String? sourceEventId,
    required String? rawType,
    required int itemId,
    required String itemName,
    required String? itemBarcode,
    required String? fromLocation,
    required String? toLocation,
    required int quantity,
  }) {
    final fingerprint = [
      remoteTaskId?.trim().toUpperCase() ?? '',
      sourceEventId?.trim().toUpperCase() ?? '',
      rawType?.trim().toUpperCase() ?? '',
      itemId.toString(),
      itemName.trim().toUpperCase(),
      itemBarcode?.trim().toUpperCase() ?? '',
      fromLocation?.trim().toUpperCase() ?? '',
      toLocation?.trim().toUpperCase() ?? '',
      quantity.toString(),
    ].join('|');
    return _taskIdsByFingerprint.putIfAbsent(fingerprint, () => _nextLocalTaskId--);
  }

  TaskEntity? _parseUnifiedTask(Map<String, dynamic> data) {
    final rawType = _asString(data['task_type']);
    final rawId = _asString(data['id']);
    if (rawType == null || rawId == null) return null;

    final detail = _asMap(data['detail']);
    final product = _asMap(detail?['product']) ?? _asMap(detail?['item']);
    final subtitleLocation = _resolveUnifiedSubtitleLocation(
      rawType: rawType,
      subtitle: _asString(data['subtitle']),
    );
    final toLocation = _asString(_firstNonNull([
      detail?['to_location'],
      detail?['toLocation'],
      detail?['target_location_code'],
      detail?['targetLocationCode'],
      detail?['location_code'],
      detail?['locationCode'],
    ]));
    final toLocationId = _asString(_firstNonNull([
      detail?['to_location_id'],
      detail?['toLocationId'],
      detail?['target_location_id'],
      detail?['targetLocationId'],
      detail?['location_id'],
      detail?['locationId'],
    ]));
    final fromLocation = _asString(_firstNonNull([
      detail?['from_location'],
      detail?['fromLocation'],
      detail?['source_location'],
      detail?['sourceLocation'],
      detail?['source_location_code'],
      detail?['sourceLocationCode'],
      detail?['bulk_location'],
      detail?['bulkLocation'],
    ]));
    final itemId = _toInt(_firstNonNull([
          detail?['item_id'],
          detail?['itemId'],
          detail?['product_id'],
          detail?['productId'],
          product?['item_id'],
          product?['id'],
          product?['product_id'],
          product?['productId'],
        ])) ??
        0;
    final itemName = _asString(_firstNonNull([
          data['product_name'],
          data['productName'],
          detail?['product_name'],
          detail?['productName'],
          detail?['item_name'],
          detail?['itemName'],
          product?['product_name'],
          product?['productName'],
          product?['item_name'],
          product?['itemName'],
          data['title'],
        ])) ??
        'Unknown item';
    final itemBarcode = _asString(_firstNonNull([
      detail?['product_barcode'],
      detail?['productBarcode'],
      detail?['item_barcode'],
      detail?['itemBarcode'],
      detail?['barcode'],
      detail?['sku'],
      detail?['upc'],
      detail?['ean'],
      detail?['product_code'],
      detail?['productCode'],
      detail?['receipt_number'],
      detail?['receiptNumber'],
      product?['product_barcode'],
      product?['productBarcode'],
      product?['item_barcode'],
      product?['itemBarcode'],
      product?['barcode'],
      product?['sku'],
      product?['upc'],
      product?['ean'],
      product?['product_code'],
      product?['productCode'],
      data['product_barcode'],
      data['productBarcode'],
      data['item_barcode'],
      data['itemBarcode'],
      data['barcode'],
      data['sku'],
      data['upc'],
      data['ean'],
    ]));
    final quantity = _toInt(_firstNonNull([
          detail?['quantity'],
          detail?['qty'],
          detail?['expected_quantity'],
          detail?['expectedQuantity'],
          data['quantity'],
          data['qty'],
          data['expected_quantity'],
          data['expectedQuantity'],
        ])) ??
        0;
    final sourceEventId = _asString(_firstNonNull([
      data['source_event_id'],
      data['sourceEventId'],
      detail?['source_event_id'],
      detail?['sourceEventId'],
    ]));
    final workflowData = rawType == 'cycle_count'
        ? _buildCycleCountWorkflowData(data)
        : const <String, Object?>{};
    final id = int.tryParse(rawId) ??
        _stableLocalIdForRemoteTask(
          remoteTaskId: rawId,
          sourceEventId: sourceEventId,
          rawType: rawType,
          itemId: itemId,
          itemName: itemName,
          itemBarcode: itemBarcode,
          fromLocation: fromLocation,
          toLocation: toLocation,
          quantity: quantity,
        );
    final status = _toTaskStatus(_asString(data['status']));
    final zone = _deriveUnifiedTaskZone(
          toLocation: toLocation,
          fromLocation: fromLocation,
          subtitleLocation: subtitleLocation,
        ) ??
        '';

    return TaskEntity(
      id: id,
      remoteTaskId: rawId,
      apiTaskType: rawType,
      type: _toUnifiedTaskType(rawType),
      itemId: itemId,
      itemName: itemName,
      itemBarcode: itemBarcode,
      itemImageUrl: _normalizeImageUrl(_asString(_firstNonNull([
        data['product_image'],
        data['productImage'],
        detail?['product_image'],
        detail?['productImage'],
        detail?['item_image'],
        detail?['itemImage'],
        detail?['item_image_url'],
        detail?['itemImageUrl'],
        product?['product_image'],
        product?['productImage'],
        product?['item_image'],
        product?['itemImage'],
        product?['item_image_url'],
        product?['itemImageUrl'],
      ]))),
      fromLocation: fromLocation,
      toLocation: toLocation ?? subtitleLocation,
      toLocationId: toLocationId,
      quantity: quantity,
      assignedTo: status == TaskStatus.pending ? null : '__worker__',
      status: status,
      createdBy: 'system',
      zone: zone,
      createdAt: DateTime.now(),
      source: TaskSource.manual,
      priority: _toTaskPriority(_asString(data['priority'])),
      sourceEventId: sourceEventId,
      workflowData: workflowData,
    );
  }

  bool _matchesRequestedZone(TaskEntity task, String? normalizedZone) {
    if (normalizedZone == null) return true;

    final taskZone = _normalizeZone(task.zone);
    if (taskZone == null) {
      return true;
    }

    if (taskZone == normalizedZone) {
      return true;
    }

    return false;
  }

  String? _deriveUnifiedTaskZone({
    required String? toLocation,
    required String? fromLocation,
    required String? subtitleLocation,
  }) {
    return _zoneFromLocationText(toLocation) ??
        _zoneFromLocationText(fromLocation) ??
        _zoneFromExplicitZoneText(subtitleLocation);
  }

  Map<String, Object?> _buildCycleCountWorkflowData(Map<String, dynamic> data) {
    final products = data['products'];
    if (products is List) {
      final parsedProducts = products
          .whereType<Map>()
          .map((entry) => Map<String, Object?>.from(entry))
          .where((entry) {
            final quantity = _toInt(entry['quantity']) ?? 0;
            return quantity > 0;
          })
          .toList(growable: false);
      if (parsedProducts.isNotEmpty) {
        return <String, Object?>{
          'cycleCountMode': 'full_shelf',
          'products': parsedProducts,
        };
      }
    }

    return const <String, Object?>{};
  }

  String? _resolveUnifiedSubtitleLocation({
    required String rawType,
    required String? subtitle,
  }) {
    final trimmed = subtitle?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final normalizedSubtitle = trimmed.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    final normalizedType = rawType.trim().toLowerCase();
    if (normalizedSubtitle == normalizedType) {
      return null;
    }

    return trimmed;
  }

  String? _zoneFromLocationText(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final upper = value.trim().toUpperCase();
    final explicitZone = RegExp(r'\bZ(\d{1,3})\b').firstMatch(upper);
    if (explicitZone != null) {
      return 'Z${explicitZone.group(1)!.padLeft(2, '0')}';
    }

    final structuredLocation =
        RegExp(r'^[A-Z_]+-(\d{1,3})(?:-\d{1,3})+').firstMatch(upper);
    if (structuredLocation != null) {
      return 'Z${structuredLocation.group(1)!.padLeft(2, '0')}';
    }

    return null;
  }

  String? _zoneFromExplicitZoneText(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final match = RegExp(r'\bZ(\d{1,3})\b').firstMatch(value.trim().toUpperCase());
    if (match == null) return null;

    return 'Z${match.group(1)!.padLeft(2, '0')}';
  }

  String _remoteTaskIdFor(TaskEntity task) {
    final remoteId = task.remoteTaskId?.trim();
    if (remoteId != null && remoteId.isNotEmpty) return remoteId;
    return task.id.toString();
  }

  String _workerTaskType(TaskEntity task) {
    final apiType = task.apiTaskType?.trim().toLowerCase();
    if (apiType != null && apiType.isNotEmpty) {
      return apiType;
    }
    final type = task.type;
    switch (type) {
      case TaskType.receive:
        return 'receiving';
      case TaskType.move:
        return 'putaway';
      case TaskType.returnTask:
        return 'return';
      case TaskType.adjustment:
        return 'cycle_count';
      case TaskType.cycleCount:
        return 'cycle_count';
      case TaskType.refill:
        return 'restock';
      case TaskType.exception:
        return 'putaway';
    }
  }

  TaskType _toUnifiedTaskType(String? rawType) {
    final text = rawType?.trim().toLowerCase() ?? '';
    switch (text) {
      case 'receiving':
        return TaskType.receive;
      case 'putaway':
        return TaskType.receive;
      case 'restock':
        return TaskType.refill;
      case 'return':
        return TaskType.returnTask;
      case 'cycle_count':
        return TaskType.cycleCount;
      default:
        return _toTaskType(rawType);
    }
  }

  TaskStatus _toTaskStatus(String? statusText) {
    final text = statusText?.trim().toLowerCase() ?? '';
    if (text.isEmpty ||
        text == 'pending' ||
        text == 'open' ||
        text == 'queued' ||
        text == 'assigned') {
      return TaskStatus.pending;
    }
    if (text.contains('progress') ||
        text.contains('started') ||
        text.contains('receiving') ||
        text.contains('in progress') ||
        text == 'active') {
      return TaskStatus.inProgress;
    }
    if (text == 'done' || text.contains('complete')) {
      return TaskStatus.completed;
    }
    return TaskStatus.pending;
  }

  TaskPriority _toTaskPriority(String? rawPriority) {
    final text = rawPriority?.trim().toLowerCase() ?? '';
    switch (text) {
      case 'urgent':
      case 'critical':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  TaskType _toTaskType(String? rawType) {
    final text = rawType?.trim().toLowerCase() ?? '';
    switch (text) {
      case 'receive':
      case 'receiving':
      case 'putaway':
        return TaskType.receive;
      case 'move':
      case 'transfer':
        return TaskType.move;
      case 'return':
      case 'return_task':
      case 'returntask':
        return TaskType.returnTask;
      case 'adjust':
      case 'adjustment':
        return TaskType.adjustment;
      case 'refill':
      case 'replenishment':
        return TaskType.refill;
      case 'exception':
        return TaskType.exception;
      case 'cycle_count':
      case 'cyclecount':
        return TaskType.cycleCount;
      default:
        return TaskType.move;
    }
  }

  String? _normalizeZone(String? zone) {
    if (zone == null || zone.trim().isEmpty) return null;
    final value = zone.trim().toUpperCase();
    final match = RegExp(r'Z?\d+').firstMatch(value);
    if (match == null) return value;
    final matched = match.group(0)!;
    if (matched.startsWith('Z')) return matched;
    return 'Z${matched.padLeft(2, '0')}';
  }

  TaskEntity _cloneTask({
    required TaskEntity task,
    int? id,
    String? remoteTaskId,
    String? apiTaskType,
    TaskType? type,
    int? itemId,
    String? itemName,
    String? itemBarcode,
    String? itemImageUrl,
    String? fromLocation,
    String? toLocation,
    String? toLocationId,
    int? quantity,
    String? assignedTo,
    TaskStatus? status,
    String? createdBy,
    String? zone,
    DateTime? createdAt,
    TaskSource? source,
    TaskPriority? priority,
    String? sourceEventId,
    Map<String, Object?>? workflowData,
  }) {
    return TaskEntity(
      id: id ?? task.id,
      remoteTaskId: remoteTaskId ?? task.remoteTaskId,
      apiTaskType: apiTaskType ?? task.apiTaskType,
      type: type ?? task.type,
      itemId: itemId ?? task.itemId,
      itemName: itemName ?? task.itemName,
      itemBarcode: itemBarcode ?? task.itemBarcode,
      itemImageUrl: itemImageUrl ?? task.itemImageUrl,
      fromLocation: fromLocation ?? task.fromLocation,
      toLocation: toLocation ?? task.toLocation,
      toLocationId: toLocationId ?? task.toLocationId,
      quantity: quantity ?? task.quantity,
      assignedTo: assignedTo,
      status: status ?? task.status,
      createdBy: createdBy ?? task.createdBy,
      zone: zone ?? task.zone,
      createdAt: createdAt ?? task.createdAt,
      source: source ?? task.source,
      priority: priority ?? task.priority,
      sourceEventId: sourceEventId ?? task.sourceEventId,
      workflowData: workflowData ?? task.workflowData,
    );
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  String? _normalizeImageUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://')) {
      return 'https://${value.substring('http://'.length)}';
    }
    return value;
  }

  dynamic _firstNonNull(Iterable<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
