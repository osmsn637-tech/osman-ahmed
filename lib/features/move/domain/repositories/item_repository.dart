import '../../../../core/utils/result.dart';
import '../entities/item_detail.dart';
import '../entities/move_item_params.dart';
import '../entities/movement.dart';
import '../../../cycle/domain/entities/cycle_count.dart';
import '../../../cycle/domain/entities/cycle_count_item.dart';
import '../../../cycle/domain/entities/submit_cycle_count_params.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';
import '../../../receive/domain/entities/receive_item_params.dart';

abstract class ItemRepository {
  Future<Result<ItemDetail>> fetchItemDetail(String barcode);
  Future<Result<Movement>> moveItem(MoveItemParams params);
  Future<Result<void>> receiveItem(ReceiveItemParams params);
  Future<Result<List<CycleCountItem>>> fetchLocationItems(int locationId);
  Future<Result<CycleCount>> submitCycleCount(SubmitCycleCountParams params);
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(String barcode);
  Future<Result<void>> adjustStock(StockAdjustmentParams params);
}
