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
      totalQuantity: 550,
      locations: [
        ItemLocationEntity(
          locationId: 1,
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

  test('canSubmit stays false until location and explicit quantity are present', () {
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
    expect(gateway.lastParams!.newQuantity, 0);
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
    expect(gateway.lastParams!.newQuantity, 1);
    expect(gateway.lastParams!.reason, 'Count Correction');
    expect(gateway.lastParams!.workerId, 'worker-1');
    expect(gateway.lastParams!.note, isNull);
    expect(controller.state.success, isTrue);
  });

  test('editing selected location code updates the resolved location id', () async {
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
    controller.updateSelectedLocationCode('Z012-BLK-A01-L02-P05');
    controller.setQuantityText('3');

    await controller.submitForItem(summary);

    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.locationId, 1111014889);
    expect(gateway.lastParams!.locationBarcode, 'Z012-BLK-A01-L02-P05');
    expect(gateway.lastParams!.newQuantity, 3);
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
