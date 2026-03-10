import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_location_summary_entity.dart';
import '../repositories/item_repository.dart';

class LookupItemByBarcodeUseCase {
  LookupItemByBarcodeUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<ItemLocationSummaryEntity>> call(String barcode) {
    final value = _normalizeBarcode(barcode);
    if (value.isEmpty) {
      return Future.value(
        const Failure<ItemLocationSummaryEntity>(
          ValidationException('Enter a valid barcode'),
        ),
      );
    }
    return _repository.getItemLocations(value);
  }

  String _normalizeBarcode(String barcode) {
    return barcode
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '')
        .trim();
  }
}
