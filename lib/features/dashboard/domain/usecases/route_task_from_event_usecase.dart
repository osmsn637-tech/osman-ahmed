import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class RouteTaskFromEventUseCase {
  RouteTaskFromEventUseCase(this._taskRepository);

  final TaskRepository _taskRepository;

  Future<TaskEntity> execute(TaskTriggerEvent event) async {
    _validate(event);

    final existing = await _taskRepository.findBySourceEventId(event.sourceEventId);
    if (existing != null) return existing;

    final now = event.createdAt ?? DateTime.now();
    final task = TaskEntity(
      id: now.microsecondsSinceEpoch,
      type: event.taskType,
      itemId: event.itemId,
      itemName: event.itemName,
      fromLocation: event.fromLocation,
      toLocation: event.toLocation,
      quantity: event.quantity,
      assignedTo: null,
      status: TaskStatus.pending,
      createdBy: event.createdBy,
      zone: _resolveZone(event),
      createdAt: now,
      source: event.source,
      priority: event.priority,
      sourceEventId: event.sourceEventId,
    );

    return _taskRepository.createTask(task);
  }

  void _validate(TaskTriggerEvent event) {
    if (event.sourceEventId.trim().isEmpty) {
      throw ArgumentError('sourceEventId is required for idempotency');
    }
    if (event.itemName.trim().isEmpty) {
      throw ArgumentError('itemName is required');
    }
    if (event.quantity <= 0) {
      throw ArgumentError('quantity must be greater than zero');
    }

    if (event.taskType == TaskType.refill) {
      final from = event.fromLocation?.toUpperCase() ?? '';
      final to = event.toLocation?.toUpperCase() ?? '';
      if (!from.startsWith('BULK')) {
        throw ArgumentError('Refill source must be a BULK location');
      }
      if (!to.startsWith('SHELF')) {
        throw ArgumentError('Refill destination must be a SHELF location');
      }
    }
  }

  String _resolveZone(TaskTriggerEvent event) {
    final location = event.toLocation ?? event.fromLocation;
    if (location == null || location.isEmpty) return 'Z01';

    final match = RegExp(r'(\d{2})').firstMatch(location);
    final zoneNum = match == null ? 1 : int.tryParse(match.group(1)!) ?? 1;
    final bounded = zoneNum.clamp(1, 12);
    return 'Z${bounded.toString().padLeft(2, '0')}';
  }
}

class TaskTriggerEvent {
  const TaskTriggerEvent._({
    required this.sourceEventId,
    required this.taskType,
    required this.source,
    required this.priority,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.createdBy,
    this.fromLocation,
    this.toLocation,
    this.createdAt,
  });

  final String sourceEventId;
  final TaskType taskType;
  final TaskSource source;
  final TaskPriority priority;
  final int itemId;
  final String itemName;
  final int quantity;
  final String? fromLocation;
  final String? toLocation;
  final String createdBy;
  final DateTime? createdAt;

  factory TaskTriggerEvent.inboundReturn({
    required String sourceEventId,
    required int itemId,
    required String itemName,
    required int quantity,
    required String toLocation,
    required String createdBy,
    DateTime? createdAt,
  }) {
    return TaskTriggerEvent._(
      sourceEventId: sourceEventId,
      taskType: TaskType.returnTask,
      source: TaskSource.inbound,
      priority: TaskPriority.high,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      toLocation: toLocation,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory TaskTriggerEvent.inboundReceive({
    required String sourceEventId,
    required int itemId,
    required String itemName,
    required int quantity,
    required String toLocation,
    required String createdBy,
    DateTime? createdAt,
  }) {
    return TaskTriggerEvent._(
      sourceEventId: sourceEventId,
      taskType: TaskType.receive,
      source: TaskSource.inbound,
      priority: TaskPriority.medium,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      toLocation: toLocation,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory TaskTriggerEvent.stockAlertRefill({
    required String sourceEventId,
    required int itemId,
    required String itemName,
    required int quantity,
    required String fromLocation,
    required String toLocation,
    required String createdBy,
    DateTime? createdAt,
  }) {
    return TaskTriggerEvent._(
      sourceEventId: sourceEventId,
      taskType: TaskType.refill,
      source: TaskSource.stockAlert,
      priority: TaskPriority.high,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      fromLocation: fromLocation,
      toLocation: toLocation,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory TaskTriggerEvent.systemMoveException({
    required String sourceEventId,
    required int itemId,
    required String itemName,
    required int quantity,
    String? fromLocation,
    String? toLocation,
    required String createdBy,
    DateTime? createdAt,
  }) {
    return TaskTriggerEvent._(
      sourceEventId: sourceEventId,
      taskType: TaskType.exception,
      source: TaskSource.systemMove,
      priority: TaskPriority.high,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      fromLocation: fromLocation,
      toLocation: toLocation,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory TaskTriggerEvent.managerCycleCount({
    required String sourceEventId,
    required int itemId,
    required String itemName,
    required int quantity,
    String? fromLocation,
    required String createdBy,
    DateTime? createdAt,
  }) {
    return TaskTriggerEvent._(
      sourceEventId: sourceEventId,
      taskType: TaskType.cycleCount,
      source: TaskSource.managerDashboard,
      priority: TaskPriority.medium,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      fromLocation: fromLocation,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
