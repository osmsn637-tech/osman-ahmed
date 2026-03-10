import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class ClaimTaskUseCase {
  ClaimTaskUseCase(this._repo);

  final TaskRepository _repo;

  Future<TaskEntity> execute({required int taskId, required String workerId}) {
    return _repo.claimTask(taskId: taskId, workerId: workerId);
  }
}
