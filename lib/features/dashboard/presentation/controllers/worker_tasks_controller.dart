import 'package:flutter/foundation.dart';

import '../../domain/entities/adjustment_task_entities.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/complete_task_usecase.dart';
import '../../domain/usecases/get_tasks_for_zone_usecase.dart';
import '../../domain/usecases/claim_task_usecase.dart';
import '../../domain/usecases/get_task_suggestion_usecase.dart';
import '../../domain/usecases/scan_adjustment_location_usecase.dart';
import '../../domain/usecases/report_task_issue_usecase.dart';
import '../../domain/usecases/save_cycle_count_progress_usecase.dart';
import '../../domain/usecases/skip_task_usecase.dart';
import '../../domain/usecases/submit_adjustment_count_usecase.dart';
import '../../domain/usecases/validate_task_location_usecase.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../models/task_detail_resume_state.dart';

class WorkerTasksState {
  const WorkerTasksState({
    this.loading = false,
    this.current = const [],
    this.completed = const [],
  });

  final bool loading;
  final List<TaskEntity> current;
  final List<TaskEntity> completed;

  WorkerTasksState copyWith({
    bool? loading,
    List<TaskEntity>? current,
    List<TaskEntity>? completed,
  }) {
    return WorkerTasksState(
      loading: loading ?? this.loading,
      current: current ?? this.current,
      completed: completed ?? this.completed,
    );
  }
}

class WorkerTasksController extends ChangeNotifier {
  WorkerTasksController({
    required GetTasksForZoneUseCase getTasksForZone,
    required ClaimTaskUseCase claimTask,
    required CompleteTaskUseCase completeTask,
    required GetTaskSuggestionUseCase getTaskSuggestion,
    ReportTaskIssueUseCase? reportTaskIssue,
    required ScanAdjustmentLocationUseCase scanAdjustmentLocation,
    required SaveCycleCountProgressUseCase saveCycleCountProgress,
    SkipTaskUseCase? skipTask,
    required SubmitAdjustmentCountUseCase submitAdjustmentCount,
    required ValidateTaskLocationUseCase validateTaskLocation,
    required SessionController session,
  })  : _getTasksForZone = getTasksForZone,
        _claimTask = claimTask,
        _completeTask = completeTask,
        _getTaskSuggestion = getTaskSuggestion,
        _reportTaskIssue = reportTaskIssue,
        _scanAdjustmentLocation = scanAdjustmentLocation,
        _saveCycleCountProgress = saveCycleCountProgress,
        _skipTask = skipTask,
        _submitAdjustmentCount = submitAdjustmentCount,
        _validateTaskLocation = validateTaskLocation,
        _session = session,
        _state = const WorkerTasksState();

  final GetTasksForZoneUseCase _getTasksForZone;
  final ClaimTaskUseCase _claimTask;
  final CompleteTaskUseCase _completeTask;
  final GetTaskSuggestionUseCase _getTaskSuggestion;
  final ReportTaskIssueUseCase? _reportTaskIssue;
  final ScanAdjustmentLocationUseCase _scanAdjustmentLocation;
  final SaveCycleCountProgressUseCase _saveCycleCountProgress;
  final SkipTaskUseCase? _skipTask;
  final SubmitAdjustmentCountUseCase _submitAdjustmentCount;
  final ValidateTaskLocationUseCase _validateTaskLocation;
  final SessionController _session;
  final Map<int, TaskDetailResumeState> _taskDetailResumeStates =
      <int, TaskDetailResumeState>{};

  WorkerTasksState _state;
  String? _activeTaskType;
  WorkerTasksState get state => _state;
  String? get activeTaskType => _activeTaskType;

  TaskDetailResumeState? taskDetailResumeStateFor(int taskId) {
    return _taskDetailResumeStates[taskId];
  }

  void saveTaskDetailResumeState(int taskId, TaskDetailResumeState state) {
    if (state.isInitial) {
      clearTaskDetailResumeState(taskId);
      return;
    }
    _taskDetailResumeStates[taskId] = state;
  }

  void clearTaskDetailResumeState(int taskId) {
    _taskDetailResumeStates.remove(taskId);
  }

  Future<void> load() async {
    await _loadForTaskType(_activeTaskType);
  }

  Future<void> applyTaskTypeFilter(String? taskType) async {
    _activeTaskType = taskType;
    await _loadForTaskType(taskType);
  }

  Future<void> _loadForTaskType(String? taskType) async {
    _state = _state.copyWith(loading: true);
    notifyListeners();
    try {
      final tasks = await _getTasksForZone.execute('', taskType: taskType);
      final visibleTasks = _visibleTasksForWorker(tasks);
      final current = visibleTasks.where((t) => !t.isCompleted).toList();
      final completed = visibleTasks.where((t) => t.isCompleted).toList();
      _pruneTaskDetailResumeStates(current);
      _state = _state.copyWith(
        current: current,
        completed: completed,
        loading: false,
      );
    } catch (_) {
      _state = _state.copyWith(loading: false);
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<TaskEntity?> claim(int taskId) async {
    final workerId = _session.state.user?.id;
    if (workerId == null) return null;
    final claimed =
        await _claimTask.execute(taskId: taskId, workerId: workerId);
    await load();
    for (final task in _state.current) {
      if (task.id == taskId &&
          task.assignedTo == workerId &&
          task.status == TaskStatus.inProgress) {
        return task;
      }
    }
    return claimed;
  }

  Future<void> complete(
    int taskId, {
    int? quantity,
    String? locationId,
    List<Map<String, Object?>>? cycleCountItems,
  }) async {
    await _completeTask.execute(
      taskId,
      quantity: quantity,
      locationId: locationId,
      cycleCountItems: cycleCountItems,
    );
    await load();
  }

  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    final updated = await _saveCycleCountProgress.execute(
      taskId,
      progress: progress,
    );
    await load();
    return updated;
  }

  Future<void> continueCycleCountLater(
    int taskId, {
    required Map<String, Object?> progress,
  }) async {
    await _saveCycleCountProgress.execute(
      taskId,
      progress: progress,
    );
    if (_skipTask != null) {
      await _skipTask.execute(taskId);
    }
    await load();
  }

  Future<String?> getSuggestion(int taskId) {
    return _getTaskSuggestion.execute(taskId);
  }

  Future<void> reportTaskIssue(
    int taskId, {
    required String note,
    String? photoPath,
  }) async {
    final reportTaskIssue = _reportTaskIssue;
    if (reportTaskIssue == null) {
      return;
    }
    await reportTaskIssue.execute(
      taskId: taskId,
      note: note,
      photoPath: photoPath,
    );
    await load();
  }

  Future<Map<String, dynamic>> validateLocation(int taskId, String barcode) {
    return _validateTaskLocation.execute(taskId: taskId, barcode: barcode);
  }

  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation(
    int taskId,
    String barcode,
  ) {
    return _scanAdjustmentLocation.execute(taskId: taskId, barcode: barcode);
  }

  Future<void> submitAdjustmentCount(
    int taskId, {
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  }) {
    return _submitAdjustmentCount.execute(
      taskId: taskId,
      adjustmentItemId: adjustmentItemId,
      quantity: quantity,
      notes: notes,
    );
  }

  List<TaskEntity> _visibleTasksForWorker(List<TaskEntity> tasks) {
    final workerId = _session.state.user?.id.trim();
    if (workerId == null || workerId.isEmpty) {
      return tasks;
    }

    return tasks.where((task) {
      final assignedTo = task.assignedTo?.trim();
      return assignedTo == null || assignedTo.isEmpty || assignedTo == workerId;
    }).toList(growable: false);
  }

  void _pruneTaskDetailResumeStates(List<TaskEntity> currentTasks) {
    final activeTaskIds = currentTasks.map((task) => task.id).toSet();
    _taskDetailResumeStates.removeWhere(
      (taskId, _) => !activeTaskIds.contains(taskId),
    );
  }
}
