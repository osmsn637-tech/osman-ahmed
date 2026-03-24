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
      locationId: 1,
      newQuantity: 2,
      reason: 'Damaged',
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
    await scrollTo(tester, find.byKey(const Key('location-row-1-0')));

    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.byKey(const Key('location-row-1-0')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_value')));
    expect(find.byKey(const Key('adjust_quantity_value')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adjust_reason_field')));
    await tester.pumpAndSettle();
    expect(find.text('Damaged'), findsWidgets);
    expect(find.text('Return'), findsWidgets);
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

  testWidgets('adjust mode quantity stepper never goes negative',
      (tester) async {
    await tester.pumpWidget(
      buildApp(buildRouter(mode: ItemLookupPageMode.adjust)),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('location-row-1-0')));
    await tester.tap(find.byKey(const Key('location-row-1-0')));
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_decrement')));

    await tester.tap(find.byKey(const Key('adjust_quantity_decrement')));
    await tester.pump();
    expect(find.text('0'), findsWidgets);

    await scrollTo(tester, find.byKey(const Key('adjust_quantity_increment')));
    await tester.tap(find.byKey(const Key('adjust_quantity_increment')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('adjust_quantity_value'))).data,
      '1',
    );
  });

  testWidgets('adjust mode confirm success returns after submit',
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

    await scrollTo(tester, find.byKey(const Key('location-row-1-0')));
    await tester.tap(find.byKey(const Key('location-row-1-0')));
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_increment')));
    await tester.tap(find.byKey(const Key('adjust_quantity_increment')));
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_reason_field')));
    await tester.tap(find.byKey(const Key('adjust_reason_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_note_field')));
    await tester.enterText(
        find.byKey(const Key('adjust_note_field')), 'box torn');
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(gateway.lastParams, isNotNull);
    expect(gateway.lastParams!.note, 'box torn');
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

    await scrollTo(tester, find.byKey(const Key('location-row-1-0')));
    await tester.tap(find.byKey(const Key('location-row-1-0')));
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_quantity_increment')));
    await tester.tap(find.byKey(const Key('adjust_quantity_increment')));
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('adjust_reason_field')));
    await tester.tap(find.byKey(const Key('adjust_reason_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjust_confirm_button')));
    await tester.tap(find.byKey(const Key('adjust_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Adjust Item'), findsOneWidget);
    expect(find.text('Exception: adjust failed'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('adjust_quantity_value'))).data,
      '1',
    );
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
