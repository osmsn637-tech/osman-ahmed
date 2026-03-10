import 'package:flutter/foundation.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/get_tasks_for_zone_usecase.dart';
import '../../../auth/presentation/providers/session_provider.dart';

class SupervisorTasksState {
  const SupervisorTasksState({this.loading = false, this.tasks = const [], this.zone = ''});

  final bool loading;
  final List<TaskEntity> tasks;
  final String zone;

  SupervisorTasksState copyWith({bool? loading, List<TaskEntity>? tasks, String? zone}) {
    return SupervisorTasksState(
      loading: loading ?? this.loading,
      tasks: tasks ?? this.tasks,
      zone: zone ?? this.zone,
    );
  }
}

class SupervisorTasksController extends ChangeNotifier {
  SupervisorTasksController({
    required GetTasksForZoneUseCase getTasksForZone,
    required SessionController session,
  })
      : _getTasksForZone = getTasksForZone,
        _session = session,
        _state = SupervisorTasksState(zone: session.state.user?.zone ?? '');

  final GetTasksForZoneUseCase _getTasksForZone;
  final SessionController _session;

  SupervisorTasksState _state;
  SupervisorTasksState get state => _state;

  Future<void> load() async {
    final zone = _state.zone.isNotEmpty ? _state.zone : (_session.state.user?.zone ?? '');
    if (zone.isEmpty) return;
    _state = _state.copyWith(loading: true, zone: zone);
    notifyListeners();
    try {
      final tasks = await _getTasksForZone.execute(zone);
      _state = _state.copyWith(tasks: tasks, loading: false);
    } catch (_) {
      _state = _state.copyWith(loading: false);
    }
    notifyListeners();
  }

  Future<void> setZone(String zone) async {
    _state = _state.copyWith(zone: zone);
    notifyListeners();
    await load();
  }

}
