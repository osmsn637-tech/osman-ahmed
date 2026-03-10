import 'package:flutter/foundation.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/complete_task_usecase.dart';
import '../../domain/usecases/get_tasks_for_zone_usecase.dart';
import '../../domain/usecases/claim_task_usecase.dart';
import '../../domain/usecases/get_task_suggestion_usecase.dart';
import '../../domain/usecases/validate_task_location_usecase.dart';
import '../../../auth/presentation/providers/session_provider.dart';

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
    required ValidateTaskLocationUseCase validateTaskLocation,
    required SessionController session,
  })
      : _getTasksForZone = getTasksForZone,
        _claimTask = claimTask,
        _completeTask = completeTask,
        _getTaskSuggestion = getTaskSuggestion,
        _validateTaskLocation = validateTaskLocation,
        _session = session,
        _state = const WorkerTasksState();

  final GetTasksForZoneUseCase _getTasksForZone;
  final ClaimTaskUseCase _claimTask;
  final CompleteTaskUseCase _completeTask;
  final GetTaskSuggestionUseCase _getTaskSuggestion;
  final ValidateTaskLocationUseCase _validateTaskLocation;
  final SessionController _session;

  WorkerTasksState _state;
  WorkerTasksState get state => _state;

  Future<void> load() async {
    final zone = _session.state.user?.zone;
    if (zone == null || zone.isEmpty) return;
    _state = _state.copyWith(loading: true);
    notifyListeners();
    try {
      final tasks = await _getTasksForZone.execute(zone);
      final current = tasks.where((t) => !t.isCompleted).toList();
      final completed = tasks.where((t) => t.isCompleted).toList();
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
    final claimed = await _claimTask.execute(taskId: taskId, workerId: workerId);
    await load();
    for (final task in _state.current) {
      if (task.id == taskId) return task;
    }
    return claimed;
  }

  Future<void> complete(
    int taskId, {
    int? quantity,
    String? locationId,
  }) async {
    await _completeTask.execute(
      taskId,
      quantity: quantity,
      locationId: locationId,
    );
    await load();
  }

  Future<String?> getSuggestion(int taskId) {
    return _getTaskSuggestion.execute(taskId);
  }

  Future<Map<String, dynamic>> validateLocation(int taskId, String barcode) {
    return _validateTaskLocation.execute(taskId: taskId, barcode: barcode);
  }
}
