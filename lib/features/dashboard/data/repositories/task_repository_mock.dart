import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/exception_entity.dart';
import '../../domain/entities/ai_alert_entity.dart';
import '../../domain/entities/adjustment_task_entities.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/entities/task_entity.dart';

class TaskRepositoryMock implements TaskRepository {
  TaskRepositoryMock();

  static final Map<String, List<TaskEntity>> _store = {};
  static int _nextId = 10;

  static void reset() {
    _store.clear();
    _nextId = 10;
  }

  static List<TaskEntity> _ensureZone(String zone) {
    if (_store.containsKey(zone)) return _store[zone]!;
    _store[zone] = [
      _mockTask(
        id: 1,
        type: TaskType.receive,
        zone: zone,
        status: TaskStatus.pending,
        itemName: 'Demo Receive Task',
        itemBarcode: '123456789011',
        toLocation: 'BULK-01-02',
      ),
      _mockTask(
        id: 2,
        type: TaskType.move,
        zone: zone,
        status: TaskStatus.inProgress,
        itemName: 'Demo Move Task',
        itemBarcode: '123456789022',
        fromLocation: 'Z01-C01-L01-P01',
        toLocation: 'Z01-C02-L02-P03',
      ),
    ];
    return _store[zone]!;
  }

  @override
  Future<DashboardSummaryEntity> getDashboardSummary() async {
    // Static demo counters for home buttons
    return const DashboardSummaryEntity(
      pendingPutawayCount: 5,
      pendingMoveCount: 3,
      exceptionCount: 2,
      cycleCountTasks: 4,
    );
  }

  @override
  Future<List<ExceptionEntity>> getExceptions() async {
    // Simple open exceptions list
    return const [
      ExceptionEntity(
        id: 1,
        itemName: 'Item A - Mispick',
        expectedLocation: 'A01-01-01',
        warehouseId: 1,
        status: 'open',
      ),
      ExceptionEntity(
        id: 2,
        itemName: 'Item B - Shortage',
        expectedLocation: 'B02-03-02',
        warehouseId: 1,
        status: 'open',
      ),
    ];
  }

  @override
  Future<void> resolveException(
      {required int id, required String action}) async {
    // No-op in mock mode
    return;
  }

  @override
  Future<List<AiAlertEntity>> getAiAlerts() async {
    // Keep empty for now; can extend later
    return const [];
  }

  static TaskEntity _mockTask(
      {required int id,
      required TaskType type,
      required String zone,
      required TaskStatus status,
      String? itemName,
      String? itemBarcode,
      String? itemImageUrl,
      String? fromLocation,
      String? toLocation,
      int? quantity,
      Map<String, Object?> workflowData = const <String, Object?>{}}) {
    return TaskEntity(
      id: id,
      type: type,
      itemId: 1000 + id,
      itemName: itemName ?? 'Demo Item $id',
      itemBarcode: itemBarcode ?? '1234567890$id',
      itemImageUrl: itemImageUrl,
      fromLocation:
          fromLocation ?? (type == TaskType.receive ? null : 'Z01-C01-L01-P01'),
      toLocation: toLocation ??
          (type == TaskType.returnTask
              ? 'Z01-BLK-C01-L01-P01'
              : 'Z01-C02-L02-P03'),
      quantity: quantity ?? (5 + id),
      assignedTo: null,
      status: status,
      createdBy: '99',
      zone: zone,
      createdAt: DateTime.now(),
      source: TaskSource.manual,
      priority: TaskPriority.medium,
      workflowData: workflowData,
    );
  }

  @override
  Future<List<TaskEntity>> getTasksForZone(String zone) async {
    final list = _ensureZone(zone);
    return List<TaskEntity>.from(list);
  }

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) async {
    // Workers pull zone 01 by default in mock
    return getTasksForZone('Z01');
  }

  @override
  Future<TaskEntity?> findBySourceEventId(String sourceEventId) async {
    for (final tasks in _store.values) {
      for (final task in tasks) {
        if (task.sourceEventId == sourceEventId) return task;
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
    for (final entry in _store.entries) {
      final idx = entry.value.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        final existing = entry.value[idx];
        final nextQuantity = quantity == null || quantity <= 0
            ? existing.quantity
            : quantity;
        final nextLocation = locationId ?? existing.toLocation;
        final updated = TaskEntity(
          id: existing.id,
          type: existing.type,
          itemId: existing.itemId,
          itemName: existing.itemName,
          fromLocation: existing.fromLocation,
          toLocation: nextLocation,
          quantity: nextQuantity,
          assignedTo: existing.assignedTo,
          status: TaskStatus.completed,
          createdBy: existing.createdBy,
          zone: existing.zone,
          createdAt: existing.createdAt,
          source: existing.source,
          priority: existing.priority,
          sourceEventId: existing.sourceEventId,
          itemBarcode: existing.itemBarcode,
          itemImageUrl: existing.itemImageUrl,
          workflowData: existing.workflowData,
        );
        entry.value[idx] = updated;
        return updated;
      }
    }
    // fallback if not found
    return _mockTask(
        id: taskId,
        type: TaskType.move,
        zone: 'Z01',
        status: TaskStatus.completed);
  }

  @override
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    for (final entry in _store.entries) {
      final idx = entry.value.indexWhere((t) => t.id == taskId);
      if (idx == -1) continue;
      final existing = entry.value[idx];
      final workflowData = Map<String, Object?>.from(existing.workflowData)
        ..['cycleCountProgress'] = progress;
      final updated = TaskEntity(
        id: existing.id,
        type: existing.type,
        itemId: existing.itemId,
        itemName: existing.itemName,
        fromLocation: existing.fromLocation,
        toLocation: existing.toLocation,
        quantity: existing.quantity,
        assignedTo: existing.assignedTo,
        status: existing.status,
        createdBy: existing.createdBy,
        zone: existing.zone,
        createdAt: existing.createdAt,
        source: existing.source,
        priority: existing.priority,
        sourceEventId: existing.sourceEventId,
        itemBarcode: existing.itemBarcode,
        itemImageUrl: existing.itemImageUrl,
        workflowData: workflowData,
      );
      entry.value[idx] = updated;
      return updated;
    }

    return _mockTask(
      id: taskId,
      type: TaskType.cycleCount,
      zone: 'Z01',
      status: TaskStatus.inProgress,
      workflowData: <String, Object?>{'cycleCountProgress': progress},
    );
  }

  @override
  Future<TaskEntity> claimTask(
      {required int taskId, required String workerId}) async {
    for (final entry in _store.entries) {
      final idx = entry.value.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        final existing = entry.value[idx];
        final updated = TaskEntity(
          id: existing.id,
          type: existing.type,
          itemId: existing.itemId,
          itemName: existing.itemName,
          fromLocation: existing.fromLocation,
          toLocation: existing.toLocation,
          quantity: existing.quantity,
          assignedTo: workerId,
          status: TaskStatus.inProgress,
          createdBy: existing.createdBy,
          zone: existing.zone,
          createdAt: existing.createdAt,
          source: existing.source,
          priority: existing.priority,
          sourceEventId: existing.sourceEventId,
          itemBarcode: existing.itemBarcode,
          itemImageUrl: existing.itemImageUrl,
          workflowData: existing.workflowData,
        );
        entry.value[idx] = updated;
        return updated;
      }
    }
    return _mockTask(
        id: taskId,
        type: TaskType.move,
        zone: 'Z01',
        status: TaskStatus.inProgress);
  }

  @override
  Future<Map<String, dynamic>> suggestTask(int taskId) async {
    final task = _findTask(taskId);
    if (task == null) {
      return const {};
    }
    return {
      'locationCode': task.toLocation,
      'taskId': taskId.toString(),
    };
  }

  @override
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  }) async {
    final task = _findTask(taskId);
    final expected = (task?.toLocation ?? task?.fromLocation ?? '').trim().toUpperCase();
    return {'valid': barcode.trim().toUpperCase() == expected};
  }

  @override
  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation({
    required int taskId,
    required String barcode,
  }) async {
    return const AdjustmentTaskLocationScan(
      locationId: 'loc-1',
      locationCode: 'Z01-A01',
      products: [
        AdjustmentTaskProduct(
          adjustmentItemId: 'adj-item-1',
          productId: 'prod-1',
          productName: 'Demo Adjust Product',
          systemQuantity: 10,
          counted: false,
        ),
      ],
    );
  }

  @override
  Future<void> submitAdjustmentCount({
    required int taskId,
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  }) async {}

  static TaskEntity addAutoReceiveTask({
    required int itemId,
    required String itemName,
    required int quantity,
    required String createdBy,
    String? toLocation,
    String? zone,
    String? assignedTo,
    TaskType type = TaskType.receive,
    String? fromLocation,
    DateTime? createdAt,
    TaskSource source = TaskSource.inbound,
    TaskPriority priority = TaskPriority.medium,
    String? sourceEventId,
    String? itemBarcode,
    String? itemImageUrl,
    Map<String, Object?> workflowData = const <String, Object?>{},
  }) {
    final resolvedZone =
        (zone == null || zone.isEmpty) ? _zoneFromLocation(toLocation) : zone;
    final list = _ensureZone(resolvedZone);
    final newTask = TaskEntity(
      id: _nextId++,
      type: type,
      itemId: itemId,
      itemName: itemName,
      fromLocation: fromLocation,
      toLocation: toLocation,
      quantity: quantity,
      assignedTo: assignedTo,
      status: TaskStatus.pending,
      createdBy: createdBy,
      zone: resolvedZone,
      createdAt: createdAt ?? DateTime.now(),
      source: source,
      priority: priority,
      sourceEventId: sourceEventId,
      itemBarcode: itemBarcode,
      itemImageUrl: itemImageUrl,
      workflowData: workflowData,
    );
    list.add(newTask);
    return newTask;
  }

  static String _zoneFromLocation(String? location) {
    if (location == null || location.isEmpty) return 'Z01';
    final match = RegExp(r'(\d{2})').firstMatch(location);
    final zoneNum = match == null ? 1 : int.tryParse(match.group(1)!) ?? 1;
    final bounded = zoneNum.clamp(1, 12);
    return 'Z${bounded.toString().padLeft(2, '0')}';
  }

  static TaskEntity? _findTask(int taskId) {
    for (final tasks in _store.values) {
      for (final task in tasks) {
        if (task.id == taskId) return task;
      }
    }
    return null;
  }
}
