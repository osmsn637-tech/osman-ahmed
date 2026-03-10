import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/features/move/data/repositories/item_repository_mock.dart';
import 'package:putaway_app/features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import 'package:putaway_app/features/move/presentation/controllers/item_lookup_controller.dart';
import 'package:putaway_app/features/move/presentation/pages/item_lookup_result_page.dart';

void main() {
  GoRouter buildRouter() {
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
          builder: (context, state) => ChangeNotifierProvider<ItemLookupController>(
            create: (_) => ItemLookupController(
              lookupItemByBarcode: LookupItemByBarcodeUseCase(
                const ItemRepositoryMock(),
              ),
            ),
            child: ItemLookupResultPage(
              barcode: state.pathParameters['barcode'] ?? '',
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('opens item lookup result page with mocked item data', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Item Lookup Result'), findsOneWidget);
    expect(find.text('Hajer Water'), findsOneWidget);
    expect(find.text('Shelf Locations'), findsOneWidget);
    expect(find.text('Bulk Locations'), findsOneWidget);
    expect(find.text('Total Locations'), findsOneWidget);
  });

  testWidgets('shows mock item image on result page', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('back button returns to home route', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
