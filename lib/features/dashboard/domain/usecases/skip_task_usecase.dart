import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class SkipTaskUseCase {
  const SkipTaskUseCase(this._repo);

  final TaskRepository _repo;

  Future<TaskEntity> execute(int taskId, {String? reason}) {
    return _repo.skipTask(taskId, reason: reason);
  }
}
