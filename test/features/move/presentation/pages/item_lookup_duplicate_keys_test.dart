import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/core/utils/result.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/features/move/data/repositories/item_repository_mock.dart';
import 'package:putaway_app/features/move/domain/entities/item_location_entity.dart';
import 'package:putaway_app/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:putaway_app/features/move/domain/entities/stock_adjustment_params.dart';
import 'package:putaway_app/features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import 'package:putaway_app/features/move/presentation/controllers/item_adjustment_controller.dart';
import 'package:putaway_app/features/move/presentation/controllers/item_lookup_controller.dart';
import 'package:putaway_app/features/move/presentation/pages/item_lookup_result_page.dart';

void main() {
  GoRouter buildRouter() {
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

    return GoRouter(
      initialLocation: '/item-lookup/result/6287009170024',
      routes: [
        GoRoute(
          path: '/item-lookup/result/:barcode',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<ItemLookupController>(
                create: (_) => ItemLookupController(
                  lookupItemByBarcode: LookupItemByBarcodeUseCase(
                    const _DuplicateLocationItemRepository(),
                  ),
                ),
              ),
              ChangeNotifierProvider<ItemAdjustmentController>(
                create: (_) => ItemAdjustmentController(
                  adjustStock: (_) async => const Success<void>(null),
                  session: session,
                ),
              ),
            ],
            child: ItemLookupResultPage(
              barcode: state.pathParameters['barcode'] ?? '',
              mode: ItemLookupPageMode.adjust,
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('adjust mode tolerates duplicate location ids', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.text('Z012-C01-L02-P02'), findsOneWidget);
    expect(find.text('Z012-C01-L02-P03'), findsOneWidget);
  });
}

class _DuplicateLocationItemRepository extends ItemRepositoryMock {
  const _DuplicateLocationItemRepository();

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(String barcode) async {
    return const Success<ItemLocationSummaryEntity>(
      ItemLocationSummaryEntity(
        itemId: 1001,
        itemName: 'Hajer Water',
        barcode: '6287009170024',
        itemImageUrl: 'assets/images/hajer_water.jpg',
        totalQuantity: 275,
        locations: [
          ItemLocationEntity(
            locationId: 1,
            zone: 'Z012',
            type: 'shelf',
            code: 'Z012-C01-L02-P02',
            quantity: 150,
          ),
          ItemLocationEntity(
            locationId: 1,
            zone: 'Z012',
            type: 'shelf',
            code: 'Z012-C01-L02-P03',
            quantity: 125,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) async {
    return const Success<void>(null);
  }
}
