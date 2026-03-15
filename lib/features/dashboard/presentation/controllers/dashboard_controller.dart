import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_dashboard_tasks_usecase.dart';
import '../state/dashboard_state.dart';
import '../../domain/repositories/task_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required GetDashboardTasksUseCase getTasksUseCase,
    required TaskRepository taskRepository,
  })
      : _getTasksUseCase = getTasksUseCase,
        _taskRepository = taskRepository,
        _state = const DashboardState();

  final GetDashboardTasksUseCase _getTasksUseCase;
  final TaskRepository _taskRepository;

  DashboardState _state;
  DashboardState get state => _state;

  Timer? _pollTimer;

  Future<void> load({bool force = false}) async {
    if (_state.isLoading && !force) return;
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _getTasksUseCase();
      final alerts = await _taskRepository.getAiAlerts();
      _setState(
        _state.copyWith(
          isLoading: false,
          summary: result.summary,
          exceptions: result.exceptions,
          aiAlerts: alerts,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  void startAutoRefresh({Duration interval = const Duration(minutes: 3)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => load(force: true));
  }

  void stopAutoRefresh() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setState(DashboardState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
