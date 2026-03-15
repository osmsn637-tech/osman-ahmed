import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class SaveCycleCountProgressUseCase {
  SaveCycleCountProgressUseCase(this._repo);

  final TaskRepository _repo;

  Future<TaskEntity> execute(
    int taskId, {
    required Map<String, Object?> progress,
  }) {
    return _repo.saveCycleCountProgress(taskId, progress: progress);
  }
}
