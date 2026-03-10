import '../../../../core/utils/result.dart';
import '../entities/item_location_summary_entity.dart';
import '../repositories/item_repository.dart';

class GetItemLocationsUseCase {
  GetItemLocationsUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<ItemLocationSummaryEntity>> call(String barcode) {
    return _repository.getItemLocations(barcode);
  }
}
