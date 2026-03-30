import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:wherehouse/features/dashboard/domain/entities/ai_alert_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/exception_entity.dart';
import 'package:wherehouse/features/dashboard/domain/entities/task_entity.dart';
import 'package:wherehouse/features/dashboard/domain/repositories/task_repository.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/claim_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/complete_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_task_suggestion_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/get_tasks_for_zone_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/report_task_issue_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/scan_adjustment_location_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/skip_task_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart';
import 'package:wherehouse/features/dashboard/domain/usecases/validate_task_location_usecase.dart';
import 'package:wherehouse/features/dashboard/presentation/controllers/worker_tasks_controller.dart';
import 'package:wherehouse/features/dashboard/presentation/models/task_detail_resume_state.dart';

void main() {
  test('load shows tasks from any zone for workers', () async {
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
    final repository = _FakeTaskRepository.withTasks(
      const <TaskEntity>[
        TaskEntity(
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
        ),
        TaskEntity(
          id: 2,
          type: TaskType.receive,
          itemId: 2,
          itemName: 'Zone B Putaway',
          itemBarcode: '223456789012',
          fromLocation: 'STAGE-02',
          toLocation: 'Z02-C02-L01-P01',
          quantity: 3,
          assignedTo: null,
          status: TaskStatus.pending,
          createdBy: 'system',
          zone: 'Z02',
        ),
      ],
    );
    final controller = WorkerTasksController(
      getTasksForZone: GetTasksForZoneUseCase(repository),
      claimTask: ClaimTaskUseCase(repository),
      completeTask: CompleteTaskUseCase(repository),
      getTaskSuggestion: GetTaskSuggestionUseCase(repository),
      reportTaskIssue: ReportTaskIssueUseCase(repository),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(repository),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(repository),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(repository),
      validateTaskLocation: ValidateTaskLocationUseCase(repository),
      session: session,
    );

    await controller.load();

    expect(repository.lastRequestedZone, isEmpty);
    expect(
      controller.state.current.map((task) => task.id),
      unorderedEquals([1, 2]),
    );
  });

  test('claim returns the newly claimed task when refreshed list is stale',
      () async {
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
      reportTaskIssue: ReportTaskIssueUseCase(repository),
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

  test('task detail resume state stores current tasks and prunes stale entries',
      () async {
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
      reportTaskIssue: ReportTaskIssueUseCase(repository),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(repository),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(repository),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(repository),
      validateTaskLocation: ValidateTaskLocationUseCase(repository),
      session: session,
    );

    controller.saveTaskDetailResumeState(
      1,
      const TaskDetailResumeState(page: 1),
    );
    controller.saveTaskDetailResumeState(
      999,
      const TaskDetailResumeState(page: 1),
    );

    await controller.load();

    expect(
      controller.taskDetailResumeStateFor(1),
      const TaskDetailResumeState(page: 1),
    );
    expect(controller.taskDetailResumeStateFor(999), isNull);

    controller.saveTaskDetailResumeState(
      1,
      const TaskDetailResumeState.initial(),
    );
    expect(controller.taskDetailResumeStateFor(1), isNull);
  });

  test(
      'continue cycle count later saves progress, skips task, and reloads pending',
      () async {
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
    final repository = _FakeTaskRepository.cycleCount();
    final controller = WorkerTasksController(
      getTasksForZone: GetTasksForZoneUseCase(repository),
      claimTask: ClaimTaskUseCase(repository),
      completeTask: CompleteTaskUseCase(repository),
      getTaskSuggestion: GetTaskSuggestionUseCase(repository),
      reportTaskIssue: ReportTaskIssueUseCase(repository),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(repository),
      skipTask: SkipTaskUseCase(repository),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(repository),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(repository),
      validateTaskLocation: ValidateTaskLocationUseCase(repository),
      session: session,
    );

    await controller.load();
    await controller.continueCycleCountLater(
      7,
      progress: const <String, Object?>{
        'items': [
          {
            'key': 'SKU-007',
            'itemName': 'Saved Item',
            'barcode': 'SKU-007',
            'countedQuantity': 4,
            'completed': true,
          },
        ],
        'location': 'SHELF-07-01',
        'locationValidated': true,
      },
    );

    expect(repository.savedProgress, isNotNull);
    expect(repository.skipCalled, isTrue);
    expect(controller.state.current, hasLength(1));
    expect(controller.state.current.single.status, TaskStatus.pending);
    expect(
        controller.state.current.single.cycleCountProgressItems, hasLength(1));
    expect(
      controller
          .state.current.single.cycleCountProgressItems.single.countedQuantity,
      4,
    );
  });

  test('reportTaskIssue forwards note and photo path to repository', () async {
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
      reportTaskIssue: ReportTaskIssueUseCase(repository),
      scanAdjustmentLocation: ScanAdjustmentLocationUseCase(repository),
      saveCycleCountProgress: SaveCycleCountProgressUseCase(repository),
      submitAdjustmentCount: SubmitAdjustmentCountUseCase(repository),
      validateTaskLocation: ValidateTaskLocationUseCase(repository),
      session: session,
    );

    await controller.reportTaskIssue(
      1,
      note: 'Broken tote',
      photoPath: 'C:/tmp/tote.jpg',
    );

    expect(repository.reportedNote, 'Broken tote');
    expect(repository.reportedPhotoPath, 'C:/tmp/tote.jpg');
  });
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository()
      : _tasks = <TaskEntity>[_defaultTask],
        _current = _defaultTask;
  _FakeTaskRepository.withTasks(List<TaskEntity> tasks)
      : _tasks = List<TaskEntity>.from(tasks),
        _current = tasks.first;
  _FakeTaskRepository.cycleCount()
      : _tasks = <TaskEntity>[_cycleCountTask],
        _current = _cycleCountTask;

  static const TaskEntity _defaultTask = TaskEntity(
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

  static const TaskEntity _cycleCountTask = TaskEntity(
    id: 7,
    type: TaskType.cycleCount,
    itemId: 7,
    itemName: 'Count SKU in SHELF-07-01',
    itemBarcode: 'SKU-007',
    fromLocation: null,
    toLocation: 'SHELF-07-01',
    quantity: 1,
    assignedTo: 'worker-1',
    status: TaskStatus.inProgress,
    createdBy: 'system',
    zone: 'Z01',
    workflowData: <String, Object?>{
      'cycleCountMode': 'single_item',
      'expectedQuantity': 1,
    },
  );

  final List<TaskEntity> _tasks;
  TaskEntity _current;
  Map<String, Object?>? savedProgress;
  bool skipCalled = false;
  String? reportedNote;
  String? reportedPhotoPath;
  String? lastRequestedZone;

  @override
  Future<TaskEntity> claimTask(
      {required int taskId, required String workerId}) async {
    _setCurrent(TaskEntity(
      id: _current.id,
      type: _current.type,
      itemId: _current.itemId,
      itemName: _current.itemName,
      itemBarcode: _current.itemBarcode,
      fromLocation: _current.fromLocation,
      toLocation: _current.toLocation,
      quantity: _current.quantity,
      assignedTo: workerId,
      status: TaskStatus.inProgress,
      createdBy: _current.createdBy,
      zone: _current.zone,
      workflowData: _current.workflowData,
    ));
    return _current;
  }

  @override
  Future<List<TaskEntity>> getTasksForZone(String zone) async {
    lastRequestedZone = zone;
    return _tasks.where((task) => zone.isEmpty || task.zone == zone).toList();
  }

  @override
  Future<void> reportTaskIssue({
    required int taskId,
    required String note,
    String? photoPath,
  }) async {
    reportedNote = note;
    reportedPhotoPath = photoPath;
  }

  @override
  Future<TaskEntity> completeTask(int taskId,
      {int? quantity,
      String? locationId,
      List<Map<String, Object?>>? cycleCountItems}) {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    savedProgress = progress;
    _setCurrent(TaskEntity(
      id: _current.id,
      type: _current.type,
      itemId: _current.itemId,
      itemName: _current.itemName,
      itemBarcode: _current.itemBarcode,
      fromLocation: _current.fromLocation,
      toLocation: _current.toLocation,
      quantity: _current.quantity,
      assignedTo: _current.assignedTo,
      status: _current.status,
      createdBy: _current.createdBy,
      zone: _current.zone,
      workflowData: <String, Object?>{
        ..._current.workflowData,
        'cycleCountProgress': progress,
      },
    ));
    return _current;
  }

  @override
  Future<TaskEntity> skipTask(int taskId, {String? reason}) async {
    skipCalled = true;
    _setCurrent(TaskEntity(
      id: _current.id,
      type: _current.type,
      itemId: _current.itemId,
      itemName: _current.itemName,
      itemBarcode: _current.itemBarcode,
      fromLocation: _current.fromLocation,
      toLocation: _current.toLocation,
      quantity: _current.quantity,
      assignedTo: null,
      status: TaskStatus.pending,
      createdBy: _current.createdBy,
      zone: _current.zone,
      workflowData: <String, Object?>{
        ..._current.workflowData,
        if (savedProgress != null) 'cycleCountProgress': savedProgress!,
      },
    ));
    return _current;
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
  Future<List<ExceptionEntity>> getExceptions() async =>
      const <ExceptionEntity>[];

  @override
  Future<List<TaskEntity>> getTasksForWorker(String workerId) async =>
      <TaskEntity>[_current];

  @override
  Future<void> resolveException(
      {required int id, required String action}) async {}

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
    required int quantity,
    String? notes,
  }) async {}

  void _setCurrent(TaskEntity task) {
    _current = task;
    final index = _tasks.indexWhere((entry) => entry.id == task.id);
    if (index == -1) {
      _tasks.add(task);
      return;
    }
    _tasks[index] = task;
  }
}
