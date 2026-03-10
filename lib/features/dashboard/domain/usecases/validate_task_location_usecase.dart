import '../repositories/task_repository.dart';

class ValidateTaskLocationUseCase {
  ValidateTaskLocationUseCase(this._repo);

  final TaskRepository _repo;

  Future<Map<String, dynamic>> execute({
    required int taskId,
    required String barcode,
  }) {
    return _repo.validateTaskLocation(taskId: taskId, barcode: barcode);
  }
}
