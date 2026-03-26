import '../../../../core/utils/result.dart';
import '../entities/item_detail.dart';
import '../entities/location_lookup_summary_entity.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';

abstract class ItemRepository {
  Future<Result<ItemDetail>> fetchItemDetail(String barcode);
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(String barcode);
  Future<Result<LocationLookupSummaryEntity>> scanLocation(String barcode);
  Future<Result<void>> adjustStock(StockAdjustmentParams params);
}
