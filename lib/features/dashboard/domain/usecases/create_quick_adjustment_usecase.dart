import '../repositories/task_repository.dart';

class CreateQuickAdjustmentUseCase {
  CreateQuickAdjustmentUseCase(this._repo);

  final TaskRepository _repo;

  Future<QuickAdjustmentResult> execute({
    required String warehouseId,
    required int productId,
    required String locationId,
    required int systemQuantity,
    required int actualQuantity,
    String? reason,
    String? notes,
    String? batchNumber,
    String? expiryDate,
  }) {
    return _repo.createQuickAdjustment(
      warehouseId: warehouseId,
      productId: productId,
      locationId: locationId,
      systemQuantity: systemQuantity,
      actualQuantity: actualQuantity,
      reason: reason,
      notes: notes,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
    );
  }
}
