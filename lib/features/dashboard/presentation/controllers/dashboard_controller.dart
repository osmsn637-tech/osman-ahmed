import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_alert_entity.dart';
import '../../domain/usecases/get_dashboard_tasks_usecase.dart';
import '../../domain/usecases/route_task_from_event_usecase.dart';
import '../state/dashboard_state.dart';
import '../../domain/repositories/task_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required GetDashboardTasksUseCase getTasksUseCase,
    required TaskRepository taskRepository,
    required RouteTaskFromEventUseCase routeTaskFromEventUseCase,
  })
      : _getTasksUseCase = getTasksUseCase,
        _taskRepository = taskRepository,
        _routeTaskFromEventUseCase = routeTaskFromEventUseCase,
        _state = const DashboardState();

  final GetDashboardTasksUseCase _getTasksUseCase;
  final TaskRepository _taskRepository;
  final RouteTaskFromEventUseCase _routeTaskFromEventUseCase;

  DashboardState _state;
  DashboardState get state => _state;

  Timer? _pollTimer;

  Future<void> load({bool force = false}) async {
    if (_state.isLoading && !force) return;
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _getTasksUseCase();
      final alerts = await _taskRepository.getAiAlerts();
      await _routeRefillTasksFromAlerts(alerts);
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

  Future<void> _routeRefillTasksFromAlerts(List<AiAlertEntity> alerts) async {
    for (final alert in alerts) {
      if (alert.alertType != 'low_shelf_stock' || alert.resolved) {
        continue;
      }

      await _routeTaskFromEventUseCase.execute(
        TaskTriggerEvent.stockAlertRefill(
          sourceEventId: 'stock-alert:${alert.id}',
          itemId: alert.itemId,
          itemName: 'Item ${alert.itemId}',
          quantity: 1,
          fromLocation: 'BULK-${alert.locationId}',
          toLocation: 'SHELF-${alert.locationId}',
          createdBy: 'system',
          createdAt: alert.createdAt,
        ),
      );
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
