import '../../../../core/utils/result.dart';
import '../../../cycle/domain/entities/cycle_count.dart';
import '../../../cycle/domain/entities/cycle_count_item.dart';
import '../../../cycle/domain/entities/submit_cycle_count_params.dart';
import '../../domain/entities/item_detail.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';
import '../../domain/entities/move_item_params.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_remote_data_source.dart';
import '../../../receive/domain/entities/receive_item_params.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._remote);

  final ItemRemoteDataSource _remote;

  @override
  Future<Result<ItemDetail>> fetchItemDetail(String barcode) {
    return _remote.fetchStock(barcode);
  }

  @override
  Future<Result<Movement>> moveItem(MoveItemParams params) {
    return _remote.moveItem(params);
  }

  @override
  Future<Result<void>> receiveItem(ReceiveItemParams params) {
    return _remote.receiveItem(params);
  }

  @override
  Future<Result<List<CycleCountItem>>> fetchLocationItems(int locationId) {
    // TODO: implement location items fetch
    return Future.value(const Success<List<CycleCountItem>>([]));
  }

  @override
  Future<Result<CycleCount>> submitCycleCount(SubmitCycleCountParams params) {
    // TODO: implement submit cycle count
    return Future.value(const Success<CycleCount>(CycleCount(items: [])));
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(String barcode) {
    return _remote.fetchItemLocations(barcode);
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) {
    return _remote.adjustStock(params);
  }
}
