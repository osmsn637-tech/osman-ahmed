import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksForWorkerUseCase {
  GetTasksForWorkerUseCase(this._repo);

  final TaskRepository _repo;

  Future<List<TaskEntity>> execute(String workerId) {
    return _repo.getTasksForWorker(workerId);
  }
}
