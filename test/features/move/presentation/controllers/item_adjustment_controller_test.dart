import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_entity.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:wherehouse/features/move/domain/entities/stock_adjustment_params.dart';
import 'package:wherehouse/features/move/presentation/controllers/item_adjustment_controller.dart';

void main() {
  ItemLocationSummaryEntity buildSummary() {
    return const ItemLocationSummaryEntity(
      itemId: 1001,
      itemName: 'Hajer Water',
      barcode: '6287009170024',
      warehouseId: 'wh-1',
      totalQuantity: 550,
      locations: [
        ItemLocationEntity(
          locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
          zone: 'Z012',
          type: 'shelf',
          code: 'Z012-C01-L02-P02',
          quantity: 150,
        ),
      ],
    );
  }

  ItemAdjustmentController buildController(
    SessionController session,
    _FakeAdjustStockGateway gateway,
  ) {
    return ItemAdjustmentController(
      adjustStock: gateway.call,
      session: session,
    );
  }

  test('quantity starts at zero', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());

    expect(controller.state.quantity, 0);
  });

  test('selecting a location stores its id', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());
    final location = buildSummary().locations.first;

    controller.selectLocation(location);

    expect(controller.state.selectedLocationId, location.locationId);
    expect(controller.state.selectedLocationCode, location.code);
  });

  test('canSubmit stays false until location and quantity are present', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());
    final location = buildSummary().locations.first;

    expect(controller.state.canSubmit, isFalse);

    controller.selectLocation(location);
    expect(controller.state.canSubmit, isFalse);

    controller.setQuantityText('0');
    expect(controller.state.canSubmit, isTrue);
  });

  test('blank quantity stays invalid after selecting a location', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());
    final location = buildSummary().locations.first;

    controller.selectLocation(location);
    controller.setQuantityText('');

    expect(controller.state.canSubmit, isFalse);
  });

  test('submit does not adjust when quantity is entered without a location',
      () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);

    controller.setQuantityText('3');
    await controller.submitForItem(buildSummary());

    expect(controller.state.canSubmit, isFalse);
    expect(controller.state.success, isFalse);
    expect(
      controller.state.errorMessage,
      'Select a valid location and quantity.',
    );
    expect(gateway.lastParams, isNull);
  });

  test('submit allows zero quantity corrections', () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);
    final summary = buildSummary();

    controller.selectLocation(summary.locations.first);
    controller.setQuantityText('0');

    await controller.submitForItem(summary);

    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.actualQuantity, 0);
    expect(controller.state.success, isTrue);
  });

  test('positive quantities still submit', () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);
    final summary = buildSummary();

    controller.selectLocation(summary.locations.first);
    controller.setQuantityText('1');
    expect(controller.state.canSubmit, isTrue);

    await controller.submitForItem(summary);

    expect(
      gateway.lastParams,
      isNotNull,
    );
    expect(gateway.lastParams!.itemId, summary.itemId);
    expect(gateway.lastParams!.locationId, summary.locations.first.locationId);
    expect(
      gateway.lastParams!.locationBarcode,
      summary.locations.first.code,
    );
    expect(
        gateway.lastParams!.systemQuantity, summary.locations.first.quantity);
    expect(gateway.lastParams!.actualQuantity, 1);
    expect(gateway.lastParams!.workerId, 'worker-1');
    expect(gateway.lastParams!.note, isNull);
    expect(controller.state.success, isTrue);
  });

  test('submit clears submitting state when adjustStock throws', () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final controller = ItemAdjustmentController(
      adjustStock: (_) async => throw Exception('network exploded'),
      session: session,
    );
    final summary = buildSummary();

    controller.selectLocation(summary.locations.first);
    controller.setQuantityText('2');

    await controller.submitForItem(summary);

    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.success, isFalse);
    expect(controller.state.errorMessage, 'Exception: network exploded');
  });

  test('editing selected location code updates the resolved location id',
      () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);
    const summary = ItemLocationSummaryEntity(
      itemId: 1001,
      itemName: 'Hajer Water',
      barcode: '6287009170024',
      warehouseId: 'wh-1',
      totalQuantity: 550,
      locations: [
        ItemLocationEntity(
          locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
          zone: 'Z012',
          type: 'shelf',
          code: 'Z012-C01-L02-P02',
          quantity: 150,
        ),
        ItemLocationEntity(
          locationId: '019b4267-c3d0-718a-b256-6e564c8201f0',
          zone: 'Z012',
          type: 'bulk',
          code: 'Z012-BLK-A01-L02-P05',
          quantity: 400,
        ),
      ],
    );

    controller.selectLocation(summary.locations.first);
    controller.updateSelectedLocationCode(
      'Z012-BLK-A01-L02-P05',
      knownLocations: summary.locations,
    );
    controller.setQuantityText('3');

    await controller.submitForItem(summary);

    expect(gateway.lastParams, isNotNull);
    expect(
      gateway.lastParams!.locationId,
      '019b4267-c3d0-718a-b256-6e564c8201f0',
    );
    expect(gateway.lastParams!.locationBarcode, 'Z012-BLK-A01-L02-P05');
    expect(gateway.lastParams!.actualQuantity, 3);
  });

  test('typing new bulk location format marks the selection as bulk', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());

    controller.updateSelectedLocationCode('BULK A2.2');

    expect(controller.state.selectedLocationCode, 'BULK A2.2');
    expect(controller.state.selectedLocationType, 'bulk');
    expect(controller.state.selectedLocationId, isNull);
  });

  test('typing GRND location format marks the selection as ground', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());

    controller.updateSelectedLocationCode('Z03-PT01-GRND-L01-P01');

    expect(controller.state.selectedLocationCode, 'Z03-PT01-GRND-L01-P01');
    expect(controller.state.selectedLocationType, 'ground');
    expect(controller.state.selectedLocationId, isNull);
  });

  test('typing A-GRND and B-GRND location formats marks the selection as ground',
      () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());

    controller.updateSelectedLocationCode('Z03-PT01-A-GRND-L01-P01');
    expect(controller.state.selectedLocationType, 'ground');

    controller.updateSelectedLocationCode('Z03-PT01-B-GRND-L01-P01');
    expect(controller.state.selectedLocationCode, 'Z03-PT01-B-GRND-L01-P01');
    expect(controller.state.selectedLocationType, 'ground');
    expect(controller.state.selectedLocationId, isNull);
  });

  test('typed location can submit when the item has no saved locations',
      () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);
    const summary = ItemLocationSummaryEntity(
      itemId: 1001,
      itemName: 'Hajer Water',
      barcode: '6287009170024',
      warehouseId: 'wh-1',
      totalQuantity: 0,
      locations: [],
    );

    controller.updateSelectedLocationCode('Z01-A03-SS-L04-P06');
    controller.setQuantityText('8');

    expect(controller.state.canSubmit, isTrue);

    await controller.submitForItem(summary);

    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.locationBarcode, 'Z01-A03-SS-L04-P06');
    expect(gateway.lastParams!.actualQuantity, 8);
    expect(gateway.lastParams!.locationId, isEmpty);
    expect(gateway.lastParams!.systemQuantity, 0);
    expect(controller.state.success, isTrue);
  });

  test('submit still works when barcode lookup does not return warehouse id',
      () async {
    final session = SessionController();
    session.setUser(
      const User(
        id: 'worker-1',
        name: 'Worker',
        role: 'worker',
        phone: '9990000000',
        zone: 'Z01',
      ),
    );
    final gateway = _FakeAdjustStockGateway();
    final controller = buildController(session, gateway);
    const summary = ItemLocationSummaryEntity(
      itemId: 1001,
      itemName: 'Hajer Water',
      barcode: '6287009170024',
      totalQuantity: 550,
      locations: [
        ItemLocationEntity(
          locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
          zone: 'Z012',
          type: 'shelf',
          code: 'Z012-C01-L02-P02',
          quantity: 150,
        ),
      ],
    );

    controller.selectLocation(summary.locations.first);
    controller.setQuantityText('4');

    await controller.submitForItem(summary);

    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.locationBarcode, 'Z012-C01-L02-P02');
    expect(gateway.lastParams!.actualQuantity, 4);
    expect(gateway.lastParams!.warehouseId, isEmpty);
    expect(controller.state.success, isTrue);
  });
}

class _FakeAdjustStockGateway {
  StockAdjustmentParams? lastParams;
  Result<void> response = const Success<void>(null);

  Future<Result<void>> call(StockAdjustmentParams params) async {
    lastParams = params;
    return response;
  }
}
