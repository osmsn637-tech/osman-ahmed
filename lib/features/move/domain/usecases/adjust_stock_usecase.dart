import '../../../../core/utils/result.dart';
import '../entities/stock_adjustment_params.dart';
import '../repositories/item_repository.dart';

class AdjustStockUseCase {
  const AdjustStockUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<void>> call(StockAdjustmentParams params) {
    return _repository.adjustStock(params);
  }
}
