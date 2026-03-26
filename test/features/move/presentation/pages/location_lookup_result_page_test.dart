import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/move/domain/entities/location_lookup_summary_entity.dart';
import 'package:wherehouse/features/move/domain/usecases/lookup_items_by_location_usecase.dart';
import 'package:wherehouse/features/move/presentation/controllers/location_lookup_controller.dart';
import 'package:wherehouse/features/move/presentation/pages/location_lookup_result_page.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  testWidgets('location lookup result page renders scanned location items',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LocationLookupController>(
        create: (_) => LocationLookupController(
          lookupItemsByLocation: LookupItemsByLocationUseCase(
            const FakeItemRepository(
              locationLookupSummary: LocationLookupSummaryEntity(
                locationId: 'loc-101',
                locationCode: 'A10.2',
                items: [
                  LocationLookupItemEntity(
                    itemId: 1001,
                    itemName: 'Hajer Water',
                    barcode: '6287009170024',
                    quantity: 12,
                    imageUrl: 'assets/images/hajer_water.jpg',
                  ),
                ],
              ),
            ),
          ),
        ),
        child: const MaterialApp(
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LocationLookupResultPage(locationCode: 'A10.2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('A10.2'), findsWidgets);
    expect(find.text('Hajer Water'), findsOneWidget);
    expect(find.text('6287009170024'), findsOneWidget);
  });
}
