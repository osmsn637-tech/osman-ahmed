import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:putaway_app/features/dashboard/domain/entities/ai_alert_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/exception_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';
import 'package:putaway_app/features/dashboard/domain/repositories/task_repository.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:putaway_app/features/dashboard/presentation/controllers/worker_tasks_controller.dart';

void main() {
  test('claim returns the newly claimed task when refreshed list is stale', () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final repository = _FakeTaskRepository();
    final controller = WorkerTasksController(
      getTasksForZone: GetTasksForZoneUseCase(repository),
      claimTask: ClaimTaskUseCase(repository),
      completeTask: CompleteTaskUseCase(repository),
      getTaskSuggestion: GetTaskSuggestionUseCase(repository),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(repository),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(repository),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(repository),
      validateTaskLocation: ValidateTaskLocationUseCase(repository),
      session: session,
    );

    await controller.load();
    final claimed = await controller.claim(1);

    expect(claimed, isNotNull);
    expect(claimed!.status, TaskStatus.inProgress);
    expect(claimed.assignedTo, 'worker-1');
  });
}

class _FakeTaskRepository implements TaskRepository {
  final TaskEntity _pending = const TaskEntity(
    id: 1,
    type: TaskType.returnTask,
    itemId: 1,
    itemName: 'Return Tote RT-204',
    itemBarcode: '123456789012',
    fromLocation: 'RT-204',
    toLocation: 'RET-01-04',
    quantity: 6,
    assignedTo: null,
    status: TaskStatus.pending,
    createdBy: 'system',
    zone: 'Z01',
  );

  @override
  Future<TaskEntity> claimTask({required int taskId, required String workerId}) async {
    return TaskEntity(
      id: _pending.id,
      type: _pending.type,
      itemId: _pending.itemId,
      itemName: _pending.itemName,
      itemBarcode: _pending.itemBarcode,
      fromLocation: _pending.fromLocation,
      toLocation: _pending.toLocation,
      quantity: _pending.quantity,
      assignedTo: workerId,
      status: TaskStatus.inProgress,
      createdBy: _pending.createdBy,
      zone: _pending.zone,
    );
  }

  @override
  Future<List<TaskEntity>> getTasksForZone(String zone) async => <TaskEntity>[_pending];

  @override
  Future<TaskEntity> completeTask(int taskId, {int? quantity, String? locationId}) {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity?> findBySourceEventId(String sourceEventId) async => null;

  @override
  Future<List<AiAlertEntity>> getAiAlerts() async => const <AiAlertEntity>[];

  @override
  Future<DashboardSummaryEntity> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<List<ExceptionEntity>> getExceptions() async => const <ExceptionEntity>[];

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) async =>
      <TaskEntity>[_pending];

  @override
  Future<void> resolveException({required int id, required String action}) async {}

  @override
  Future<Map<String, dynamic>> suggestTask(int taskId) async =>
      const <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  }) async =>
      const <String, dynamic>{'valid': true};

  @override
  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation({
    required int taskId,
    required String barcode,
  }) async {
    return const AdjustmentTaskLocationScan(
      locationId: 'loc-1',
      locationCode: 'Z01-A01',
      products: [],
    );
  }

  @override
  Future<void> submitAdjustmentCount({
    required int taskId,
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  }) async {}
}
