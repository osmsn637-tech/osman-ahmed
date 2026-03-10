import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CompleteTaskUseCase {
  CompleteTaskUseCase(this._repo);

  final TaskRepository _repo;

  Future<TaskEntity> execute(
    int taskId, {
    int? quantity,
    String? locationId,
  }) {
    return _repo.completeTask(
      taskId,
      quantity: quantity,
      locationId: locationId,
    );
  }
}
