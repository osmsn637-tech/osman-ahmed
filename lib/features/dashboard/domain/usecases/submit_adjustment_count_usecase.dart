import '../repositories/task_repository.dart';

class SubmitAdjustmentCountUseCase {
  SubmitAdjustmentCountUseCase(this._repo);

  final TaskRepository _repo;

  Future<void> execute({
    required int taskId,
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  }) {
    return _repo.submitAdjustmentCount(
      taskId: taskId,
      adjustmentItemId: adjustmentItemId,
      quantity: quantity,
      notes: notes,
    );
  }
}
