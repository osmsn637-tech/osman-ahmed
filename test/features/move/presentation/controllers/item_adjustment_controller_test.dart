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

  test('decrement never goes below zero', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());

    controller.decrement();

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

  test('canSubmit stays false until location quantity and reason are present', () {
    final session = SessionController();
    final controller = buildController(session, _FakeAdjustStockGateway());
    final location = buildSummary().locations.first;

    expect(controller.state.canSubmit, isFalse);

    controller.selectLocation(location);
    expect(controller.state.canSubmit, isFalse);

    controller.increment();
    expect(controller.state.canSubmit, isFalse);

    controller.setReason('Damaged');
    expect(controller.state.canSubmit, isTrue);
  });

  test('submit sends selected location item reason and optional note', () async {
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
    controller.increment();
    controller.increment();
    controller.setReason('Damaged');
    controller.setNote('box torn');

    await controller.submitForItem(summary);

    expect(
      gateway.lastParams,
      isNotNull,
    );
    expect(gateway.lastParams!.itemId, summary.itemId);
    expect(gateway.lastParams!.locationId, summary.locations.first.locationId);
    expect(gateway.lastParams!.newQuantity, 2);
    expect(gateway.lastParams!.reason, 'Damaged');
    expect(gateway.lastParams!.workerId, 'worker-1');
    expect(gateway.lastParams!.note, 'box torn');
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
