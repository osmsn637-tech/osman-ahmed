import '../../../../core/utils/result.dart';
import '../../domain/entities/item_detail.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/location_lookup_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_remote_data_source.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._remote);

  final ItemRemoteDataSource _remote;

  @override
  Future<Result<ItemDetail>> fetchItemDetail(String barcode) {
    return _remote.fetchStock(barcode);
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(String barcode) {
    return _remote.fetchItemLocations(barcode);
  }

  @override
  Future<Result<LocationLookupSummaryEntity>> scanLocation(String barcode) {
    return _remote.scanLocation(barcode);
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) {
    return _remote.adjustStock(params);
  }
}
