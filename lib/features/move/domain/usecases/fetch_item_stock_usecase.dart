import '../../../../core/utils/result.dart';
import '../entities/item_detail.dart';
import '../repositories/item_repository.dart';

class FetchItemDetailUseCase {
  const FetchItemDetailUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<ItemDetail>> execute(String barcode) {
    return _repository.fetchItemDetail(barcode);
  }
}
