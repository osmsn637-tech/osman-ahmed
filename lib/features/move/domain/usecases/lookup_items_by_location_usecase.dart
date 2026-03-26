import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../entities/location_lookup_summary_entity.dart';
import '../repositories/item_repository.dart';

class LookupItemsByLocationUseCase {
  LookupItemsByLocationUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<LocationLookupSummaryEntity>> call(String locationCode) {
    final value = _normalize(locationCode);
    if (value.isEmpty) {
      return Future.value(
        const Failure<LocationLookupSummaryEntity>(
          ValidationException('Enter a valid location barcode'),
        ),
      );
    }
    return _repository.scanLocation(value);
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '').trim();
  }
}
