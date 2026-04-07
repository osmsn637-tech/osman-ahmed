import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:wherehouse/features/dashboard/domain/entities/ai_alert_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/exception_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/task_entity.dart';
import 'package:wherehouse/features/dashboard/domain/repositories/task_repository.dart';
import 'package:wherehouse/features/inbound/domain/entities/inbound_entities.dart';
import 'package:wherehouse/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:wherehouse/features/move/domain/entities/item_detail.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_entity.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:wherehouse/features/move/domain/entities/location_lookup_summary_entity.dart';
import 'package:wherehouse/features/move/domain/entities/location_stock.dart';
import 'package:wherehouse/features/move/domain/entities/stock_adjustment_params.dart';
import 'package:wherehouse/features/move/domain/repositories/item_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<TaskEntity>? tasks}) {
    if (tasks != null) {
      _tasks.addAll(tasks);
    }
  }

  final List<TaskEntity> _tasks = <TaskEntity>[];
  String? lastRequestedTaskType;

  void addTask(TaskEntity task) {
    _tasks.removeWhere((existing) => existing.id == task.id);
    _tasks.add(task);
  }

  @override
  Future<DashboardSummaryEntity> getDashboardSummary() async {
    return DashboardSummaryEntity(
      pendingPutawayCount: _tasks.where((task) => task.isPending).length,
      pendingMoveCount:
          _tasks.where((task) => task.type == TaskType.move).length,
      exceptionCount: 0,
      cycleCountTasks:
          _tasks.where((task) => task.type == TaskType.cycleCount).length,
    );
  }

  @override
  Future<List<ExceptionEntity>> getExceptions() async =>
      const <ExceptionEntity>[];

  @override
  Future<void> resolveException(
      {required int id, required String action}) async {}

  @override
  Future<List<AiAlertEntity>> getAiAlerts() async => const <AiAlertEntity>[];

  @override
  Future<List<TaskEntity>> getTasksForZone(
    String zone, {
    String? taskType,
  }) async {
    lastRequestedTaskType = taskType;
    return _tasks
        .where((task) => zone.isEmpty || task.zone == zone)
        .where((task) => _matchesTaskType(task, taskType))
        .toList();
  }

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) async {
    return _tasks.where((task) => task.assignedTo == workerId).toList();
  }

  @override
  Future<TaskEntity?> findBySourceEventId(String sourceEventId) async {
    for (final task in _tasks) {
      if (task.sourceEventId == sourceEventId) return task;
    }
    return null;
  }

  @override
  Future<TaskEntity> completeTask(
    int taskId, {
    int? quantity,
    String? locationId,
    List<Map<String, Object?>>? cycleCountItems,
  }) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    final existing = _tasks[index];
    final updated = _copyTask(
      existing,
      status: TaskStatus.completed,
      quantity: quantity != null && quantity > 0 ? quantity : existing.quantity,
      toLocation: locationId ?? existing.toLocation,
      toLocationId: locationId ?? existing.toLocationId,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    final existing = _tasks[index];
    final workflowData = Map<String, Object?>.from(existing.workflowData)
      ..['cycleCountProgress'] = progress;
    final updated = _copyTask(existing, workflowData: workflowData);
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> skipTask(int taskId, {String? reason}) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    final existing = _tasks[index];
    final updated = _copyTask(
      existing,
      assignedTo: null,
      status: TaskStatus.pending,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> claimTask({
    required int taskId,
    required String workerId,
  }) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    final existing = _tasks[index];
    final updated = _copyTask(
      existing,
      assignedTo: workerId,
      status: TaskStatus.inProgress,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Map<String, dynamic>> suggestTask(int taskId) async {
    final task = _tasks.firstWhere((entry) => entry.id == taskId);
    return <String, dynamic>{
      'locationCode': task.toLocation,
      'toLocation': task.toLocation,
      'location_id': task.toLocationId ?? task.toLocation,
    };
  }

  @override
  Future<void> reportTaskIssue({
    required int taskId,
    required String note,
    String? photoPath,
  }) async {}

  @override
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  }) async {
    final task = _tasks.firstWhere((entry) => entry.id == taskId);
    final expected =
        (task.toLocation ?? task.fromLocation ?? '').trim().toUpperCase();
    return <String, dynamic>{
      'valid': barcode.trim().toUpperCase() == expected,
    };
  }

  @override
  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation({
    required int taskId,
    required String barcode,
  }) async {
    return const AdjustmentTaskLocationScan(
      locationId: 'loc-1',
      locationCode: 'Z01-A01',
      products: <AdjustmentTaskProduct>[
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
    required int quantity,
    String? notes,
  }) async {}

  TaskEntity _copyTask(
    TaskEntity task, {
    TaskStatus? status,
    int? quantity,
    String? unit,
    String? assignedTo,
    String? toLocation,
    String? toLocationId,
    Map<String, Object?>? workflowData,
  }) {
    return TaskEntity(
      id: task.id,
      remoteTaskId: task.remoteTaskId,
      apiTaskType: task.apiTaskType,
      type: task.type,
      itemId: task.itemId,
      itemName: task.itemName,
      itemBarcode: task.itemBarcode,
      itemImageUrl: task.itemImageUrl,
      fromLocation: task.fromLocation,
      toLocation: toLocation ?? task.toLocation,
      toLocationId: toLocationId ?? task.toLocationId,
      quantity: quantity ?? task.quantity,
      unit: unit ?? task.unit,
      assignedTo: assignedTo ?? task.assignedTo,
      status: status ?? task.status,
      createdBy: task.createdBy,
      zone: task.zone,
      createdAt: task.createdAt,
      source: task.source,
      priority: task.priority,
      sourceEventId: task.sourceEventId,
      workflowData: workflowData ?? task.workflowData,
    );
  }

  bool _matchesTaskType(TaskEntity task, String? taskType) {
    if (taskType == null || taskType.isEmpty) {
      return true;
    }
    final normalizedTaskType = taskType.trim().toLowerCase();
    final taskApiType = task.apiTaskType?.trim().toLowerCase();
    if (taskApiType != null && taskApiType.isNotEmpty) {
      return taskApiType == normalizedTaskType;
    }
    return task.type.code == normalizedTaskType;
  }
}

TaskEntity buildTestTask({
  required int id,
  TaskType type = TaskType.receive,
  String zone = 'Z01',
  TaskStatus status = TaskStatus.pending,
  int itemId = 1001,
  String itemName = 'Demo Item',
  String? itemBarcode = '123456789012',
  String? itemImageUrl,
  String? apiTaskType,
  String? fromLocation,
  String? toLocation = 'Z01-C02-L02-P03',
  String? toLocationId,
  int quantity = 1,
  String? unit,
  String? assignedTo,
  Map<String, Object?> workflowData = const <String, Object?>{},
}) {
  return TaskEntity(
    id: id,
    apiTaskType: apiTaskType,
    type: type,
    itemId: itemId,
    itemName: itemName,
    itemBarcode: itemBarcode,
    itemImageUrl: itemImageUrl,
    fromLocation:
        fromLocation ?? (type == TaskType.receive ? null : 'Z01-C01-L01-P01'),
    toLocation: toLocation,
    toLocationId: toLocationId,
    quantity: quantity,
    unit: unit,
    assignedTo: assignedTo,
    status: status,
    createdBy: 'system',
    zone: zone,
    createdAt: DateTime(2026, 3, 15),
    source: TaskSource.manual,
    priority: TaskPriority.medium,
    workflowData: workflowData,
  );
}

class FakeItemRepository implements ItemRepository {
  const FakeItemRepository({
    this.summary = _defaultSummary,
    this.locationLookupSummary = _defaultLocationSummary,
    this.adjustStockResult = const Success<void>(null),
  });

  static const ItemLocationSummaryEntity _defaultSummary =
      ItemLocationSummaryEntity(
    itemId: 1001,
    itemName: 'Hajer Water',
    barcode: '6287009170024',
    warehouseId: 'wh-1',
    itemImageUrl: 'assets/images/hajer_water.jpg',
    totalQuantity: 550,
    locations: <ItemLocationEntity>[
      ItemLocationEntity(
        locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
        zone: 'Z012',
        type: 'shelf',
        code: 'Z012-C01-L02-P02',
        quantity: 150,
      ),
      ItemLocationEntity(
        locationId: '019b4267-c3d0-718a-b256-6e564c8201f0',
        zone: 'Z012',
        type: 'bulk',
        code: 'Z012-BLK-A01-L02-P05',
        quantity: 400,
      ),
    ],
  );

  static const LocationLookupSummaryEntity _defaultLocationSummary =
      LocationLookupSummaryEntity(
    locationId: 'loc-1',
    locationCode: 'A10.2',
    items: <LocationLookupItemEntity>[
      LocationLookupItemEntity(
        itemId: 1001,
        itemName: 'Hajer Water',
        barcode: '6287009170024',
        quantity: 12,
        imageUrl: 'assets/images/hajer_water.jpg',
      ),
    ],
  );

  final ItemLocationSummaryEntity summary;
  final LocationLookupSummaryEntity locationLookupSummary;
  final Result<void> adjustStockResult;

  @override
  Future<Result<ItemDetail>> fetchItemDetail(String barcode) async {
    return Success<ItemDetail>(
      ItemDetail(
        barcode: summary.barcode,
        name: summary.itemName,
        stocks: summary.locations
            .map(
              (location) => LocationStock(
                locationId: _stableIntFromString(location.locationId),
                locationName: location.code,
                quantity: location.quantity,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(
      String barcode) async {
    return Success<ItemLocationSummaryEntity>(summary);
  }

  @override
  Future<Result<LocationLookupSummaryEntity>> scanLocation(
      String barcode) async {
    return Success<LocationLookupSummaryEntity>(locationLookupSummary);
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) async {
    return adjustStockResult;
  }

  static int _stableIntFromString(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class FakeInboundRepository implements InboundRepository {
  FakeInboundRepository({
    List<InboundDocument>? documents,
    List<InboundReceipt>? receipts,
  }) {
    if (documents != null) {
      _documents.addAll(documents);
    }
    if (receipts != null) {
      for (final receipt in receipts) {
        _receipts[receipt.id] = receipt;
      }
    }
  }

  final List<InboundDocument> _documents = <InboundDocument>[];
  final Map<String, InboundReceipt> _receipts = <String, InboundReceipt>{};
  int _nextId = 100;

  @override
  Future<List<InboundDocument>> getInboundDocuments() async {
    return List<InboundDocument>.from(_documents);
  }

  @override
  Future<List<InboundDocument>> getInboundDocumentsByStatus(
    InboundStatus status,
  ) async {
    return _documents.where((document) => document.status == status).toList();
  }

  @override
  Future<InboundDocument> createInboundDocument(
      CreateInboundParams params) async {
    final items = params.items
        .map(
          (item) => InboundItem(
            id: _nextId++,
            itemId: item.itemId,
            itemName: item.itemName,
            barcode: item.barcode,
            expectedQuantity: item.expectedQuantity,
            toLocation: item.toLocation,
          ),
        )
        .toList(growable: false);
    final document = InboundDocument(
      id: _nextId++,
      documentNumber: params.documentNumber,
      supplierName: params.supplierName,
      status: InboundStatus.pending,
      items: items,
      createdBy: 1,
      createdAt: DateTime(2026, 3, 15),
      expectedArrival: params.expectedArrival,
    );
    _documents.add(document);
    return document;
  }

  @override
  Future<InboundDocument> startInboundDocument(int inboundId) async {
    final index = _documents.indexWhere((document) => document.id == inboundId);
    final updated = _documents[index].copyWith(
      status: InboundStatus.inProgress,
      startedAt: DateTime(2026, 3, 15),
    );
    _documents[index] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> receiveInboundItem(
      ReceiveInboundItemParams params) async {
    final index =
        _documents.indexWhere((document) => document.id == params.inboundId);
    final document = _documents[index];
    final updatedItems = document.items
        .map(
          (item) => item.itemId != params.itemId
              ? item
              : item.copyWith(
                  receivedQuantity:
                      item.receivedQuantity + params.receivedQuantity,
                  notes: params.notes,
                ),
        )
        .toList(growable: false);
    final updated = document.copyWith(items: updatedItems);
    _documents[index] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> completeInboundDocument(int inboundId) async {
    final index = _documents.indexWhere((document) => document.id == inboundId);
    final updated = _documents[index].copyWith(
      status: InboundStatus.completed,
      completedAt: DateTime(2026, 3, 15),
    );
    _documents[index] = updated;
    return updated;
  }

  @override
  Future<Result<InboundReceiptScanResult>> scanReceipt(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      return Failure<InboundReceiptScanResult>(
        ArgumentError('Barcode must not be empty.'),
      );
    }

    final receiptId =
        'receipt-${normalized.toLowerCase().replaceAll('rcv-', '')}';
    _receipts.putIfAbsent(
      receiptId,
      () => InboundReceipt(
        id: receiptId,
        poNumber: normalized,
        items: const [
          InboundReceiptItem(
            id: 'item-1',
            itemName: 'Demo Item',
            barcode: '123456789012',
            expectedQuantity: 12,
            imageUrl: 'https://example.com/demo-item.png',
          ),
          InboundReceiptItem(
            id: 'item-2',
            itemName: 'Backup Item',
            barcode: 'SKU-002',
            expectedQuantity: 4,
            imageUrl: 'https://example.com/backup-item.png',
          ),
        ],
      ),
    );
    return Success<InboundReceiptScanResult>(
      InboundReceiptScanResult(
        barcode: normalized,
        receiptId: receiptId,
        poNumber: normalized,
        items: _receipts[receiptId]?.items ?? const <InboundReceiptItem>[],
      ),
    );
  }

  @override
  Future<Result<InboundReceipt>> getReceipt(String receiptId) async {
    final receipt = _receipts[receiptId];
    if (receipt == null) {
      return Failure<InboundReceipt>(Exception('Receipt not found.'));
    }
    return Success<InboundReceipt>(receipt);
  }

  @override
  Future<Result<InboundReceipt>> startReceipt(String receiptId) async {
    final receipt = _receipts[receiptId];
    if (receipt == null) {
      return Failure<InboundReceipt>(Exception('Receipt not found.'));
    }
    final updated = receipt.copyWith(status: 'receiving');
    _receipts[receiptId] = updated;
    return Success<InboundReceipt>(updated);
  }

  @override
  Future<Result<InboundReceiptItem>> scanReceiptItem({
    required String receiptId,
    required String barcode,
  }) async {
    final receipt = _receipts[receiptId];
    if (receipt == null) {
      return Failure<InboundReceiptItem>(Exception('Receipt not found.'));
    }
    final normalized = barcode.trim().toUpperCase();
    final item = receipt.items.cast<InboundReceiptItem?>().firstWhere(
          (entry) => entry?.barcode.trim().toUpperCase() == normalized,
          orElse: () => null,
        );
    if (item == null) {
      return Failure<InboundReceiptItem>(Exception('Item not found.'));
    }
    return Success<InboundReceiptItem>(item);
  }

  @override
  Future<Result<InboundReceipt>> confirmReceiptItem({
    required String receiptId,
    required String itemId,
    required int quantity,
    required DateTime expirationDate,
  }) async {
    final receipt = _receipts[receiptId];
    if (receipt == null) {
      return Failure<InboundReceipt>(Exception('Receipt not found.'));
    }
    final updated = receipt.copyWith(
      items: receipt.items
          .map(
            (item) => item.id != itemId
                ? item
                : item.copyWith(
                    receivedQuantity: quantity,
                    expirationDate: expirationDate,
                  ),
          )
          .toList(growable: false),
    );
    _receipts[receiptId] = updated;
    return Success<InboundReceipt>(updated);
  }
}
