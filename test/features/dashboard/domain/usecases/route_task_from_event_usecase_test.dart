import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/features/dashboard/domain/entities/ai_alert_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/exception_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';
import 'package:putaway_app/features/dashboard/domain/repositories/task_repository.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/route_task_from_event_usecase.dart';

void main() {
  late _FakeTaskRepository repository;
  late RouteTaskFromEventUseCase useCase;

  setUp(() {
    repository = _FakeTaskRepository();
    useCase = RouteTaskFromEventUseCase(repository);
  });

  test('creates return task from inbound return event', () async {
    final task = await useCase.execute(
      TaskTriggerEvent.inboundReturn(
        sourceEventId: 'ib-1-item-100-return',
        itemId: 100,
        itemName: 'Returned Widget',
        quantity: 2,
        toLocation: 'RET-01',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000005',
      ),
    );

    expect(task.type, TaskType.returnTask);
    expect(task.source, TaskSource.inbound);
    expect(task.status, TaskStatus.pending);
    expect(task.priority, TaskPriority.high);
  });

  test('creates receive task from inbound receive confirmation', () async {
    final task = await useCase.execute(
      TaskTriggerEvent.inboundReceive(
        sourceEventId: 'ib-1-item-200-receive',
        itemId: 200,
        itemName: 'Inbound Widget',
        quantity: 5,
        toLocation: 'A01-01-01',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000009',
      ),
    );

    expect(task.type, TaskType.receive);
    expect(task.source, TaskSource.inbound);
    expect(task.toLocation, 'A01-01-01');
  });

  test('creates refill task from low shelf stock alert', () async {
    final task = await useCase.execute(
      TaskTriggerEvent.stockAlertRefill(
        sourceEventId: 'alert-7',
        itemId: 300,
        itemName: 'Shelf Item',
        quantity: 7,
        fromLocation: 'BULK-01',
        toLocation: 'SHELF-04',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000077',
      ),
    );

    expect(task.type, TaskType.refill);
    expect(task.source, TaskSource.stockAlert);
    expect(task.fromLocation, 'BULK-01');
    expect(task.toLocation, 'SHELF-04');
  });

  test('creates exception task from system move exception event', () async {
    final task = await useCase.execute(
      TaskTriggerEvent.systemMoveException(
        sourceEventId: 'move-ex-9',
        itemId: 410,
        itemName: 'Move Item',
        quantity: 1,
        fromLocation: 'A01-01-01',
        toLocation: 'A01-01-09',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000011',
      ),
    );

    expect(task.type, TaskType.exception);
    expect(task.source, TaskSource.systemMove);
    expect(task.priority, TaskPriority.high);
  });

  test('creates cycle count task from manager scheduling request', () async {
    final task = await useCase.execute(
      TaskTriggerEvent.managerCycleCount(
        sourceEventId: 'cc-2026-03-03-z01',
        itemId: 500,
        itemName: 'Cycle Item',
        quantity: 1,
        fromLocation: 'A01-01-01',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000001',
      ),
    );

    expect(task.type, TaskType.cycleCount);
    expect(task.source, TaskSource.managerDashboard);
    expect(task.priority, TaskPriority.medium);
  });

  test('returns existing task for duplicate source event id', () async {
    final event = TaskTriggerEvent.inboundReceive(
      sourceEventId: 'dup-1',
      itemId: 200,
      itemName: 'Inbound Widget',
      quantity: 5,
      toLocation: 'A01-01-01',
      createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000009',
    );

    final first = await useCase.execute(event);
    final second = await useCase.execute(event);

    expect(second.id, first.id);
    expect(repository.createdTasks.length, 1);
  });

  test('throws on refill when from location is not bulk', () async {
    final call = useCase.execute(
      TaskTriggerEvent.stockAlertRefill(
        sourceEventId: 'alert-invalid-1',
        itemId: 300,
        itemName: 'Shelf Item',
        quantity: 7,
        fromLocation: 'SHELF-01',
        toLocation: 'SHELF-04',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000077',
      ),
    );

    await expectLater(call, throwsArgumentError);
  });

  test('throws on refill when destination is not shelf', () async {
    final call = useCase.execute(
      TaskTriggerEvent.stockAlertRefill(
        sourceEventId: 'alert-invalid-2',
        itemId: 300,
        itemName: 'Shelf Item',
        quantity: 7,
        fromLocation: 'BULK-01',
        toLocation: 'BULK-04',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000077',
      ),
    );

    await expectLater(call, throwsArgumentError);
  });

  test('throws on invalid quantity', () async {
    final call = useCase.execute(
      TaskTriggerEvent.inboundReceive(
        sourceEventId: 'bad-qty',
        itemId: 200,
        itemName: 'Inbound Widget',
        quantity: 0,
        toLocation: 'A01-01-01',
        createdBy: '2bcf9d5d-1234-4f1d-8f6d-000000000009',
      ),
    );

    await expectLater(call, throwsArgumentError);
  });
}

class _FakeTaskRepository implements TaskRepository {
  final List<TaskEntity> createdTasks = [];
  int _nextId = 1;

  @override
  Future<TaskEntity?> findBySourceEventId(String sourceEventId) async {
    try {
      return createdTasks.firstWhere((task) => task.sourceEventId == sourceEventId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task) async {
    final created = TaskEntity(
      id: _nextId++,
      type: task.type,
      itemId: task.itemId,
      itemName: task.itemName,
      fromLocation: task.fromLocation,
      toLocation: task.toLocation,
      quantity: task.quantity,
      assignedTo: task.assignedTo,
      status: task.status,
      createdBy: task.createdBy,
      zone: task.zone,
      createdAt: task.createdAt,
      source: task.source,
      priority: task.priority,
      sourceEventId: task.sourceEventId,
    );
    createdTasks.add(created);
    return created;
  }

  @override
  Future<DashboardSummaryEntity> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<List<ExceptionEntity>> getExceptions() {
    throw UnimplementedError();
  }

  @override
  Future<void> resolveException({required int id, required String action}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AiAlertEntity>> getAiAlerts() {
    throw UnimplementedError();
  }

  @override
  Future<List<TaskEntity>> getTasksForZone(String zone) {
    throw UnimplementedError();
  }

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity> completeTask(
    int taskId, {
    int? quantity,
    String? locationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity> claimTask({
    required int taskId,
    required String workerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> suggestTask(int taskId) async {
    return {'locationCode': 'LOC-$taskId'};
  }

  @override
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  }) async {
    return {
      'taskId': taskId,
      'barcode': barcode,
      'valid': true,
    };
  }
}
