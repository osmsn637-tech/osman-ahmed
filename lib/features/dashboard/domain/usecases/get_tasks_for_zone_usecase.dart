import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksForZoneUseCase {
  GetTasksForZoneUseCase(this._repo);

  final TaskRepository _repo;

  Future<List<TaskEntity>> execute(String zone) {
    return _repo.getTasksForZone(zone);
  }
}
