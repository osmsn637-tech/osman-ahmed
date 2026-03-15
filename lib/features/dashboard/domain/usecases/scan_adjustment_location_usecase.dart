import '../entities/adjustment_task_entities.dart';
import '../repositories/task_repository.dart';

class ScanAdjustmentLocationUseCase {
  ScanAdjustmentLocationUseCase(this._repo);

  final TaskRepository _repo;

  Future<AdjustmentTaskLocationScan> execute({
    required int taskId,
    required String barcode,
  }) {
    return _repo.scanAdjustmentLocation(taskId: taskId, barcode: barcode);
  }
}
