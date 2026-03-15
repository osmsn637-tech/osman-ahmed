class TaskEntity {
  const TaskEntity({
    required this.id,
    this.remoteTaskId,
    this.apiTaskType,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.itemBarcode,
    this.itemImageUrl,
    required this.fromLocation,
    required this.toLocation,
    this.toLocationId,
    required this.quantity,
    this.assignedTo,
    required this.status,
    required this.createdBy,
    required this.zone,
    this.createdAt,
    this.source = TaskSource.manual,
    this.priority = TaskPriority.medium,
    this.sourceEventId,
    this.workflowData = const <String, Object?>{},
  });

  final int id;
  final String? remoteTaskId;
  final String? apiTaskType;
  final TaskType type;
  final int itemId;
  final String itemName;
  final String? itemBarcode;
  final String? itemImageUrl;
  final String? fromLocation;
  final String? toLocation;
  final String? toLocationId;
  final int quantity;
  final String? assignedTo;
  final TaskStatus status;
  final String createdBy;
  final String zone;
  final DateTime? createdAt;
  final TaskSource source;
  final TaskPriority priority;
  final String? sourceEventId;
  final Map<String, Object?> workflowData;

  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isCompleted => status == TaskStatus.completed;
  String get cycleCountMode {
    final raw = workflowData['cycleCountMode'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return 'single_item';
  }

  bool get isFullShelfCycleCount =>
      type == TaskType.cycleCount && cycleCountMode == 'full_shelf';

  bool get isSingleItemCycleCount =>
      type == TaskType.cycleCount && !isFullShelfCycleCount;

  int get cycleCountExpectedQuantity => _workflowInt('expectedQuantity') ?? quantity;

  List<CycleCountItem> get cycleCountItems {
    if (type != TaskType.cycleCount) return const <CycleCountItem>[];

    final productItems = cycleCountProducts;
    if (productItems.isNotEmpty) {
      return productItems
          .map(
            (item) => CycleCountItem(
              key: _cycleCountItemKey(
                barcode: item.barcode,
                itemName: item.itemName,
              ),
              itemName: item.itemName,
              barcode: item.barcode,
              expectedQuantity: item.expectedQuantity,
              imageUrl: item.imageUrl,
            ),
          )
          .toList(growable: false);
    }

    if (isFullShelfCycleCount) {
      return cycleCountExpectedLines
          .map(
            (line) => CycleCountItem(
              key: _cycleCountItemKey(
                barcode: line.barcode,
                itemName: line.itemName,
              ),
              itemName: line.itemName,
              barcode: line.barcode?.trim() ?? '',
              expectedQuantity: line.expectedQuantity,
            ),
          )
          .toList(growable: false);
    }

    return <CycleCountItem>[
      CycleCountItem(
        key: _cycleCountItemKey(barcode: itemBarcode, itemName: itemName),
        itemName: itemName,
        barcode: itemBarcode?.trim() ?? '',
        expectedQuantity: cycleCountExpectedQuantity,
        imageUrl: itemImageUrl,
      ),
    ];
  }

  List<CycleCountProductItem> get cycleCountProducts {
    final raw = workflowData['products'];
    if (raw is! List) return const <CycleCountProductItem>[];

    return raw
        .whereType<Map>()
        .map(
          (entry) => CycleCountProductItem.fromMap(
            Map<String, Object?>.from(entry),
          ),
        )
        .where((item) => item.expectedQuantity > 0)
        .toList(growable: false);
  }

  List<CycleCountProgressItem> get cycleCountProgressItems {
    final raw = workflowData['cycleCountProgress'];
    if (raw is! Map) return const <CycleCountProgressItem>[];
    final items = raw['items'];
    if (items is! List) return const <CycleCountProgressItem>[];

    return items
        .whereType<Map>()
        .map(
          (entry) => CycleCountProgressItem.fromMap(
            Map<String, Object?>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  Map<String, CycleCountProgressItem> get cycleCountProgressByKey {
    final items = cycleCountProgressItems;
    if (items.isEmpty) return const <String, CycleCountProgressItem>{};
    return <String, CycleCountProgressItem>{
      for (final item in items) item.key: item,
    };
  }

  String? get returnContainerId =>
      _workflowString('returnContainerId') ?? fromLocation?.trim();

  List<ReturnTaskItem> get returnItems {
    final raw = workflowData['returnItems'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => ReturnTaskItem.fromMap(Map<String, Object?>.from(entry)))
          .toList(growable: false);
    }

    return <ReturnTaskItem>[
      ReturnTaskItem(
        itemName: itemName,
        barcode: itemBarcode,
        quantity: quantity,
        imageUrl: itemImageUrl,
        location: toLocation,
      ),
    ];
  }

  List<TaskWorkflowLine> get cycleCountExpectedLines {
    final raw = workflowData['expectedLines'];
    if (raw is! List) return const <TaskWorkflowLine>[];

    return raw
        .whereType<Map>()
        .map((entry) =>
            TaskWorkflowLine.fromMap(Map<String, Object?>.from(entry)))
        .toList(growable: false);
  }

  String? _workflowString(String key) {
    final raw = workflowData[key];
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return raw?.toString();
  }

  int? _workflowInt(String key) {
    final raw = workflowData[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  String _cycleCountItemKey({
    required String? barcode,
    required String itemName,
  }) {
    final normalizedBarcode = barcode?.trim() ?? '';
    if (normalizedBarcode.isNotEmpty) {
      return normalizedBarcode.toUpperCase();
    }
    return itemName.trim().toUpperCase();
  }
}

class CycleCountItem {
  const CycleCountItem({
    required this.key,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    this.imageUrl,
  });

  final String key;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final String? imageUrl;
}

class CycleCountProgressItem {
  const CycleCountProgressItem({
    required this.key,
    required this.barcode,
    required this.countedQuantity,
    required this.completed,
  });

  final String key;
  final String barcode;
  final int countedQuantity;
  final bool completed;

  factory CycleCountProgressItem.fromMap(Map<String, Object?> data) {
    final barcode = data['barcode']?.toString().trim() ?? '';
    final itemName = data['itemName']?.toString().trim() ?? '';
    final key = data['key']?.toString().trim();
    return CycleCountProgressItem(
      key: (key != null && key.isNotEmpty)
          ? key
          : (barcode.isNotEmpty ? barcode.toUpperCase() : itemName.toUpperCase()),
      barcode: barcode,
      countedQuantity: TaskWorkflowLine._toInt(
            data['countedQuantity'] ?? data['quantity'],
          ) ??
          0,
      completed: data['completed'] == true,
    );
  }
}

class CycleCountProductItem {
  const CycleCountProductItem({
    required this.productId,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    this.imageUrl,
  });

  final String productId;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final String? imageUrl;

  factory CycleCountProductItem.fromMap(Map<String, Object?> data) {
    return CycleCountProductItem(
      productId: data['product_id']?.toString().trim() ?? '',
      itemName: (data['name'] ?? data['itemName'] ?? 'Unknown item').toString(),
      barcode: data['barcode']?.toString().trim() ?? '',
      expectedQuantity: TaskWorkflowLine._toInt(
            data['quantity'] ?? data['expectedQuantity'],
          ) ??
          0,
      imageUrl: data['image']?.toString().trim(),
    );
  }
}

class TaskWorkflowLine {
  const TaskWorkflowLine({
    required this.itemName,
    this.barcode,
    required this.expectedQuantity,
  });

  final String itemName;
  final String? barcode;
  final int expectedQuantity;

  factory TaskWorkflowLine.fromMap(Map<String, Object?> data) {
    return TaskWorkflowLine(
      itemName: (data['itemName'] ?? data['name'] ?? 'Unknown item').toString(),
      barcode: data['barcode']?.toString(),
      expectedQuantity: _toInt(
            data['expectedQuantity'] ?? data['quantity'] ?? data['expected_qty'],
          ) ??
          0,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class ReturnTaskItem {
  const ReturnTaskItem({
    required this.itemName,
    this.barcode,
    required this.quantity,
    this.imageUrl,
    this.location,
  });

  final String itemName;
  final String? barcode;
  final int quantity;
  final String? imageUrl;
  final String? location;

  factory ReturnTaskItem.fromMap(Map<String, Object?> data) {
    return ReturnTaskItem(
      itemName: (data['itemName'] ?? data['name'] ?? 'Unknown item').toString(),
      barcode: data['itemBarcode']?.toString() ?? data['barcode']?.toString(),
      quantity: TaskWorkflowLine._toInt(
            data['quantity'] ?? data['expectedQuantity'] ?? data['expected_qty'],
          ) ??
          0,
      imageUrl: data['imageUrl']?.toString() ?? data['image']?.toString(),
      location: data['location']?.toString() ?? data['toLocation']?.toString(),
    );
  }
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
