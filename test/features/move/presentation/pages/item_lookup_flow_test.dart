import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_entity.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:wherehouse/features/move/domain/repositories/item_repository.dart';
import 'package:wherehouse/features/move/domain/entities/stock_adjustment_params.dart';
import 'package:wherehouse/features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import 'package:wherehouse/features/move/presentation/controllers/item_adjustment_controller.dart';
import 'package:wherehouse/features/move/presentation/controllers/item_lookup_controller.dart';
import 'package:wherehouse/features/move/presentation/pages/item_lookup_result_page.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  GoRouter buildRouter({
    ItemLookupPageMode mode = ItemLookupPageMode.lookup,
    _FakeAdjustStockGateway? gateway,
    ItemRepository? repository,
  }) {
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
    final adjustGateway = gateway ?? _FakeAdjustStockGateway();
    final itemRepository = repository ?? const FakeItemRepository();

    return GoRouter(
      initialLocation: '/item-lookup/result/6287009170024',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
        ),
        GoRoute(
          path: '/item-lookup/result/:barcode',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider<ItemLookupController>(
                create: (_) => ItemLookupController(
                  lookupItemByBarcode: LookupItemByBarcodeUseCase(
                    itemRepository,
                  ),
                ),
              ),
              ChangeNotifierProvider<ItemAdjustmentController>(
                create: (_) => ItemAdjustmentController(
                  adjustStock: adjustGateway.call,
                  session: session,
                ),
              ),
            ],
            child: ItemLookupResultPage(
              barcode: state.pathParameters['barcode'] ?? '',
              mode: mode,
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('opens item lookup result page with mocked item data', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(buildRouter()));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Bulk Locations'));

    expect(find.text('Item Lookup Result'), findsOneWidget);
    expect(find.text('Hajer Water'), findsOneWidget);
    expect(find.text('Shelf Locations'), findsOneWidget);
    expect(find.text('Bulk Locations'), findsOneWidget);
    expect(find.text('Total Locations'), findsOneWidget);
  });

  testWidgets('shows mock item image on result page', (tester) async {
    await tester.pumpWidget(buildApp(buildRouter()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('back button returns to home route', (tester) async {
    await tester.pumpWidget(buildApp(buildRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  test('stock adjustment params supports optional note', () {
    const params = StockAdjustmentParams(
      itemId: 1001,
      warehouseId: 'wh-1',
      locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
      locationBarcode: 'Z012-C01-L02-P02',
      systemQuantity: 4,
      actualQuantity: 2,
      workerId: 'worker-1',
      note: 'box torn',
    );

    expect(params.note, 'box torn');
  });

  testWidgets('adjust mode shows selectable locations and adjustment panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(buildRouter(mode: ItemLookupPageMode.adjust)),
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );

    expect(find.text('Adjust Item'), findsOneWidget);
    expect(
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
      findsOneWidget,
    );
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    expect(find.byKey(const Key('adjust_location_code_field')), findsOneWidget);
    expect(find.byKey(const Key('adjust_quantity_field')), findsOneWidget);
    expect(find.byKey(const Key('adjust_reason_field')), findsNothing);
    expect(find.byKey(const Key('adjust_note_field')), findsNothing);
    expect(find.byKey(const Key('adjust_quantity_increment')), findsNothing);
    expect(find.byKey(const Key('adjust_quantity_decrement')), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
              find.byKey(const Key('adjust_confirm_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
      'adjust mode allows duplicate location ids without duplicate key errors',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          repository: const _DuplicateLocationItemRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.text('Z012-C01-L02-P02'), findsOneWidget);
    expect(find.text('Z012-C01-L02-P03'), findsOneWidget);
  });

  testWidgets('adjust mode success shows popup before navigating home',
      (tester) async {
    final gateway = _FakeAdjustStockGateway();

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(
      tester,
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_location_code_field')));
    await tester.enterText(
      find.byKey(const Key('adjust_location_code_field')),
      'Z012-BLK-A01-L02-P05',
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '3');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Adjustment submitted'), findsOneWidget);
    expect(
      find.text('The item adjustment was submitted successfully.'),
      findsOneWidget,
    );
    expect(
        find.byKey(const Key('adjust_success_confirm_button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('adjust_success_confirm_button')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const Key('adjust_success_confirm_button')),
      ),
      isA<ElevatedButton>(),
    );
    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.warehouseId, 'wh-1');
    expect(
        gateway.lastParams!.locationId, '019b4267-c3d0-718a-b256-6e564c8201f0');
    expect(gateway.lastParams!.locationBarcode, 'Z012-BLK-A01-L02-P05');
    expect(gateway.lastParams!.systemQuantity, 400);
    expect(gateway.lastParams!.actualQuantity, 3);
    expect(gateway.lastParams!.note, isNull);

    await tester.tap(find.byKey(const Key('adjust_success_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
      'adjust mode enables confirm after entering location and quantity', (
    tester,
  ) async {
    final gateway = _FakeAdjustStockGateway();

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(
      tester,
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '9');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    expect(
      tester
          .widget<ElevatedButton>(
              find.byKey(const Key('adjust_confirm_button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('adjust_success_confirm_button')), findsOneWidget);
    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.warehouseId, 'wh-1');
    expect(gateway.lastParams!.systemQuantity, 150);
    expect(gateway.lastParams!.actualQuantity, 9);

    await tester.tap(find.byKey(const Key('adjust_success_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
      'adjust mode keeps confirm disabled until location and quantity are provided',
      (
    tester,
  ) async {
    final gateway = _FakeAdjustStockGateway();

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '3');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));

    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('adjust_confirm_button')),
          )
          .onPressed,
      isNull,
    );
    expect(gateway.lastParams, isNull);
    expect(find.text('Adjustment submitted'), findsNothing);
  });

  testWidgets('adjust mode failure shows inline error and keeps form state', (
    tester,
  ) async {
    final gateway = _FakeAdjustStockGateway()
      ..response = Failure<void>(Exception('adjust failed'));

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(
      tester,
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '1');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.text('Exception: adjust failed'), findsOneWidget);
    expect(find.byKey(const Key('adjust_reason_field')), findsNothing);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('lookup mode remains read only', (tester) async {
    await tester.pumpWidget(buildApp(buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Item Lookup Result'), findsOneWidget);
    expect(find.byKey(const Key('adjust_quantity_value')), findsNothing);
    expect(find.byKey(const Key('adjust_confirm_button')), findsNothing);
    expect(find.text('Adjustment'), findsNothing);
  });

  testWidgets('lookup mode renders Arabic labels', (tester) async {
    await tester.pumpWidget(
      buildApp(buildRouter(), locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('مواقع التخزين'));

    expect(find.text('نتيجة البحث عن الصنف'), findsOneWidget);
    expect(find.text('مواقع الرفوف'), findsOneWidget);
    expect(find.text('مواقع التخزين'), findsOneWidget);
  });

  testWidgets(
      'lookup mode renders compact backend shelf locations under shelf section',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        buildRouter(repository: const _CompactShelfItemRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shelf Locations'), findsOneWidget);
    expect(find.text('A10.2'), findsOneWidget);
    expect(find.text('Bulk Locations'), findsNothing);
  });

  testWidgets('lookup mode renders ground locations in a separate section',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        buildRouter(repository: const _GroundLocationItemRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Ground Locations'));

    expect(find.text('Shelf Locations'), findsOneWidget);
    expect(find.text('Bulk Locations'), findsOneWidget);
    expect(find.text('Ground Locations'), findsOneWidget);
    expect(find.text('Z03-PT01-GRND-L01-P01'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('lookup mode renders plain A-GRND locations in ground section',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        buildRouter(repository: const _PlainGroundAliasItemRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Ground Locations'));

    expect(find.text('Ground Locations'), findsOneWidget);
    expect(find.text('A-GRND'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets(
      'adjust mode with no saved locations still enables confirm after typing location and quantity',
      (tester) async {
    final gateway = _FakeAdjustStockGateway();

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
          repository: const _NoLocationsItemRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No locations'), findsWidgets);

    await scrollTo(tester, find.byKey(const Key('adjust_location_code_field')));
    await tester.enterText(
      find.byKey(const Key('adjust_location_code_field')),
      'Z01-A03-SS-L04-P06',
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '8');
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    expect(
      tester
          .widget<ElevatedButton>(
              find.byKey(const Key('adjust_confirm_button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('adjust_success_confirm_button')), findsOneWidget);
    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.locationBarcode, 'Z01-A03-SS-L04-P06');
    expect(gateway.lastParams!.actualQuantity, 8);
    expect(gateway.lastParams!.locationId, isEmpty);
    expect(gateway.lastParams!.systemQuantity, 0);
  });

  testWidgets(
      'adjust mode still submits when barcode lookup does not return warehouse id',
      (tester) async {
    final gateway = _FakeAdjustStockGateway();

    await tester.pumpWidget(
      buildApp(
        buildRouter(
          mode: ItemLookupPageMode.adjust,
          gateway: gateway,
          repository: const _NoWarehouseItemRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(
      tester,
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('location-row-019b4267-c3d0-718a-b256-6e564c8201e1-0'),
      ),
    );
    await tester.pump();

    await scrollTo(tester, find.byKey(const Key('adjust_quantity_field')));
    await tester.enterText(find.byKey(const Key('adjust_quantity_field')), '4');
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('adjust_success_confirm_button')), findsOneWidget);
    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.warehouseId, isEmpty);
    expect(gateway.lastParams!.actualQuantity, 4);
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

class _DuplicateLocationItemRepository extends FakeItemRepository {
  const _DuplicateLocationItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 1001,
            itemName: 'Hajer Water',
            barcode: '6287009170024',
            itemImageUrl: 'assets/images/hajer_water.jpg',
            totalQuantity: 550,
            locations: [
              ItemLocationEntity(
                locationId: 'dup-1',
                zone: 'Z012',
                type: 'shelf',
                code: 'Z012-C01-L02-P02',
                quantity: 150,
              ),
              ItemLocationEntity(
                locationId: 'dup-1',
                zone: 'Z012',
                type: 'shelf',
                code: 'Z012-C01-L02-P03',
                quantity: 125,
              ),
            ],
          ),
        );
}

class _CompactShelfItemRepository extends FakeItemRepository {
  const _CompactShelfItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 11250,
            itemName: 'فقيه دجاج 900 جرام',
            barcode: '6281101930050',
            itemImageUrl: 'https://img.qeu.app/products/6281101930050/1.png',
            totalQuantity: 1,
            locations: [
              ItemLocationEntity(
                locationId: '101',
                zone: '',
                type: 'shelf',
                code: 'A10.2',
                quantity: 1,
              ),
            ],
          ),
        );
}

class _NoLocationsItemRepository extends FakeItemRepository {
  const _NoLocationsItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 11251,
            itemName: 'No Location Product',
            barcode: '9990001112223',
            warehouseId: 'wh-1',
            totalQuantity: 0,
            locations: [],
          ),
        );
}

class _NoWarehouseItemRepository extends FakeItemRepository {
  const _NoWarehouseItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 1001,
            itemName: 'Hajer Water',
            barcode: '6287009170024',
            totalQuantity: 150,
            locations: [
              ItemLocationEntity(
                locationId: '019b4267-c3d0-718a-b256-6e564c8201e1',
                zone: 'Z012',
                type: 'shelf',
                code: 'Z012-C01-L02-P02',
                quantity: 150,
              ),
            ],
          ),
        );
}

class _GroundLocationItemRepository extends FakeItemRepository {
  const _GroundLocationItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 1001,
            itemName: 'Hajer Water',
            barcode: '6287009170024',
            warehouseId: 'wh-1',
            totalQuantity: 551,
            locations: [
              ItemLocationEntity(
                locationId: 'shelf-1',
                zone: 'Z03',
                type: 'shelf',
                code: 'Z03-C01-SS-L01-P01',
                quantity: 150,
              ),
              ItemLocationEntity(
                locationId: 'bulk-1',
                zone: 'Z03',
                type: 'bulk',
                code: 'Z03-C01-BLK-L01-P01',
                quantity: 400,
              ),
              ItemLocationEntity(
                locationId: 'ground-1',
                zone: 'Z03',
                type: 'ground',
                code: 'Z03-PT01-GRND-L01-P01',
                quantity: 1,
              ),
            ],
          ),
        );
}

class _PlainGroundAliasItemRepository extends FakeItemRepository {
  const _PlainGroundAliasItemRepository()
      : super(
          summary: const ItemLocationSummaryEntity(
            itemId: 17303,
            itemName: 'كيت كات اصبعين 20.5جم',
            barcode: '6294017130551',
            warehouseId: '019966c3-0f2c-7950-ae4d-ae6b1d9a1fa7',
            itemImageUrl:
                'https://img.qeu.app/products/6294017130551/6294017130551_image.webp',
            totalQuantity: 230060,
            locations: [
              ItemLocationEntity(
                locationId: '3e5ace4e-fc66-4764-b5e0-e83d99672435',
                zone: 'A',
                type: 'ground',
                code: 'A-GRND',
                quantity: 230060,
              ),
            ],
          ),
        );
}

Widget buildApp(GoRouter router, {Locale? locale}) {
  return MaterialApp.router(
    routerConfig: router,
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}
