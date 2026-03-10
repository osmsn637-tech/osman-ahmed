class TaskEntity {
  const TaskEntity({
    required this.id,
    this.remoteTaskId,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.itemBarcode,
    this.itemImageUrl,
    required this.fromLocation,
    required this.toLocation,
    required this.quantity,
    this.assignedTo,
    required this.status,
    required this.createdBy,
    required this.zone,
    this.createdAt,
    this.source = TaskSource.manual,
    this.priority = TaskPriority.medium,
    this.sourceEventId,
  });

  final int id;
  final String? remoteTaskId;
  final TaskType type;
  final int itemId;
  final String itemName;
  final String? itemBarcode;
  final String? itemImageUrl;
  final String? fromLocation;
  final String? toLocation;
  final int quantity;
  final String? assignedTo;
  final TaskStatus status;
  final String createdBy;
  final String zone;
  final DateTime? createdAt;
  final TaskSource source;
  final TaskPriority priority;
  final String? sourceEventId;

  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isCompleted => status == TaskStatus.completed;
}

enum TaskType {
  receive,
  move,
  returnTask,
  adjustment,
  refill,
  exception,
  cycleCount
}

enum TaskStatus { pending, inProgress, completed }

enum TaskSource { manual, inbound, stockAlert, systemMove, managerDashboard }

enum TaskPriority { low, medium, high, critical }

extension TaskTypeCode on TaskType {
  String get code {
    switch (this) {
      case TaskType.receive:
        return 'receive';
      case TaskType.move:
        return 'move';
      case TaskType.returnTask:
        return 'return';
      case TaskType.adjustment:
        return 'adjustment';
      case TaskType.refill:
        return 'refill';
      case TaskType.exception:
        return 'exception';
      case TaskType.cycleCount:
        return 'cycle_count';
    }
  }
}

extension TaskSourceCode on TaskSource {
  String get code {
    switch (this) {
      case TaskSource.manual:
        return 'manual';
      case TaskSource.inbound:
        return 'inbound';
      case TaskSource.stockAlert:
        return 'stock_alert';
      case TaskSource.systemMove:
        return 'system_move';
      case TaskSource.managerDashboard:
        return 'manager_dashboard';
    }
  }
}
