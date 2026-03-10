import '../../../../core/utils/result.dart';
import '../../../cycle/domain/entities/cycle_count.dart';
import '../../../cycle/domain/entities/cycle_count_item.dart';
import '../../../cycle/domain/entities/submit_cycle_count_params.dart';
import '../../domain/entities/item_detail.dart';
import '../../domain/entities/item_location_entity.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/location_stock.dart';
import '../../domain/entities/move_item_params.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/stock_adjustment_params.dart';
import '../../domain/repositories/item_repository.dart';
import '../../../receive/domain/entities/receive_item_params.dart';

class ItemRepositoryMock implements ItemRepository {
  const ItemRepositoryMock();

  static const int _mockItemId = 1001;
  static const String _mockBarcode = '6287009170024';
  static const String _mockImageAsset = 'assets/images/hajer_water.jpg';

  ItemDetail _buildItemDetail() {
    return const ItemDetail(
      barcode: _mockBarcode,
      name: 'Hajer Water',
      stocks: [
        LocationStock(
          locationId: 1,
          locationName: 'Z012-C01-L02-P02',
          quantity: 150,
        ),
        LocationStock(
          locationId: 2,
          locationName: 'Z012-BLK-A01-L02-P05',
          quantity: 400,
        ),
      ],
    );
  }

  ItemLocationSummaryEntity _buildLocationSummary() {
    const locations = [
      ItemLocationEntity(
        locationId: 1,
        zone: 'Z012',
        type: 'shelf',
        code: 'Z012-C01-L02-P02',
        quantity: 150,
      ),
      ItemLocationEntity(
        locationId: 2,
        zone: 'Z012',
        type: 'bulk',
        code: 'Z012-BLK-A01-L02-P05',
        quantity: 400,
      ),
    ];

    return const ItemLocationSummaryEntity(
      itemId: _mockItemId,
      itemName: 'Hajer Water',
      barcode: _mockBarcode,
      itemImageUrl: _mockImageAsset,
      totalQuantity: 550,
      locations: locations,
    );
  }

  @override
  Future<Result<ItemDetail>> fetchItemDetail(String barcode) async {
    return Success<ItemDetail>(_buildItemDetail());
  }

  @override
  Future<Result<Movement>> moveItem(MoveItemParams params) async {
    return Success<Movement>(
      Movement(
        barcode: params.barcode,
        fromLocationId: params.fromLocationId,
        toLocationId: params.toLocationId,
        quantity: params.quantity,
        movementId: 1,
        movedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> receiveItem(ReceiveItemParams params) async {
    // Pretend success
    return const Success<void>(null);
  }

  @override
  Future<Result<List<CycleCountItem>>> fetchLocationItems(
      int locationId) async {
    return const Success<List<CycleCountItem>>([]);
  }

  @override
  Future<Result<CycleCount>> submitCycleCount(
      SubmitCycleCountParams params) async {
    return const Success<CycleCount>(CycleCount(items: []));
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(
      String barcode) async {
    return Success<ItemLocationSummaryEntity>(_buildLocationSummary());
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) async {
    return const Success<void>(null);
  }
}
