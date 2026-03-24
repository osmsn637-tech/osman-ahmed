import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/inbound/domain/entities/inbound_entities.dart';
import 'package:wherehouse/features/inbound/presentation/controllers/inbound_receipt_controller.dart';
import 'package:wherehouse/features/inbound/presentation/pages/inbound_receipt_page.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  Widget buildReceiptPage({
    required FakeInboundRepository repository,
    required String receiptId,
    InboundReceiptScanResult? initialScanResult,
    Locale locale = const Locale('en'),
  }) {
    return ChangeNotifierProvider<InboundReceiptController>(
      create: (_) => InboundReceiptController(
        repository,
        receiptId: receiptId,
        initialScanResult: initialScanResult,
      ),
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: InboundReceiptPage(receiptId: receiptId),
      ),
    );
  }

  FakeInboundRepository buildRepository() {
    return FakeInboundRepository(
      receipts: [
        const InboundReceipt(
          id: 'receipt-1001',
          poNumber: 'PO-1001',
          items: [
            InboundReceiptItem(
              id: 'item-1',
              itemName: 'Blue Mug',
              barcode: 'SKU-001',
              expectedQuantity: 4,
              imageUrl: 'https://example.com/blue-mug.png',
            ),
            InboundReceiptItem(
              id: 'item-2',
              itemName: 'Red Mug',
              barcode: 'SKU-002',
              expectedQuantity: 2,
              imageUrl: 'https://example.com/red-mug.png',
            ),
          ],
        ),
      ],
    );
  }

  InboundReceiptScanResult buildScanResult({
    String receiptId = 'receipt-1001',
    String poNumber = 'PO-1001',
    List<InboundReceiptItem> items = const [
      InboundReceiptItem(
        id: 'item-1',
        itemName: 'Blue Mug',
        barcode: 'SKU-001',
        expectedQuantity: 4,
        imageUrl: 'https://example.com/blue-mug.png',
      ),
      InboundReceiptItem(
        id: 'item-2',
        itemName: 'Red Mug',
        barcode: 'SKU-002',
        expectedQuantity: 2,
        imageUrl: 'https://example.com/red-mug.png',
      ),
    ],
  }) {
    return InboundReceiptScanResult(
      barcode: poNumber,
      receiptId: receiptId,
      poNumber: poNumber,
      items: items,
    );
  }

  testWidgets('receipt page shows receive title, po, and expected quantities',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: FakeInboundRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(poNumber: 'PO-SCANNED-1001'),
      ),
    );
    await pumpUi(tester);

    expect(find.text('Receive'), findsWidgets);
    expect(find.text('PO-SCANNED-1001'), findsOneWidget);
    expect(find.text('Blue Mug'), findsOneWidget);
    expect(find.text('SKU-001'), findsOneWidget);
    expect(find.text('Received Items'), findsOneWidget);
    expect(find.text('0 of 2 received'), findsOneWidget);
    expect(find.text('Scan item barcode'), findsOneWidget);
    expect(find.text('Expected Qty: 4'), findsOneWidget);
    expect(find.text('Expected Qty: 2'), findsOneWidget);
  });

  testWidgets('receipt page renders receive flow copy in Arabic',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: FakeInboundRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(poNumber: 'PO-SCANNED-1001'),
        locale: const Locale('ar'),
      ),
    );
    await pumpUi(tester);

    expect(find.text('استلام'), findsWidgets);
    expect(find.text('العناصر المستلمة'), findsOneWidget);
    expect(find.text('0 من 2 تم استلامها'), findsOneWidget);
    expect(find.text('امسح باركود الصنف'), findsOneWidget);
    expect(find.text('الكمية المتوقعة: 4'), findsOneWidget);
  });

  testWidgets('receipt page shows item image from the scan response',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: FakeInboundRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('inbound-receipt-item-container-item-1')),
        matching: find.byType(Image),
      ),
    );

    expect(image.image, isA<NetworkImage>());
    expect(
      (image.image as NetworkImage).url,
      'https://example.com/blue-mug.png',
    );
  });

  testWidgets('receipt detail shows expected quantity label and value',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.tap(find.text('Blue Mug'));
    await pumpUi(tester);

    expect(find.text('Expected Qty'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('receipt page shows start receiving before items are active',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    expect(find.text('Start receiving'), findsOneWidget);

    final scanField = tester.widget<TextField>(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
    );
    expect(scanField.enabled, isFalse);
  });

  testWidgets('start receiving stays below the receipt items', (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    final buttonTop = tester
        .getTopLeft(find.byKey(const Key('inbound-receipt-start-button')))
        .dy;
    final lastItemTop = tester.getTopLeft(find.text('Red Mug')).dy;

    expect(buttonTop, greaterThan(lastItemTop));
  });

  testWidgets('starting receipt unlocks item entry', (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    final scanField = tester.widget<TextField>(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
    );
    expect(scanField.enabled, isTrue);
    expect(scanField.autofocus, isTrue);

    final editableText = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('inbound-receipt-hidden-scan-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('receipt list scanner re-focuses after app resume', (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    final editableFinder = find.descendant(
      of: find.byKey(const Key('inbound-receipt-hidden-scan-field')),
      matching: find.byType(EditableText),
    );

    var editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isTrue);

    editableText.focusNode.unfocus();
    await tester.pump();
    editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpUi(tester);

    editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('tapping an item locks quantity until barcode is scanned',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.tap(find.text('Blue Mug'));
    await pumpUi(tester);

    expect(find.text('Receive Item'), findsOneWidget);
    expect(find.text('Scan or type barcode'), findsOneWidget);

    var quantityField = tester.widget<TextField>(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
    );
    expect(quantityField.enabled, isFalse);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-detail-barcode-field')),
      'SKU-001',
    );
    await pumpUi(tester);

    quantityField = tester.widget<TextField>(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
    );
    expect(quantityField.enabled, isTrue);
  });

  testWidgets('scanning an item opens detail with quantity enabled immediately',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
      'SKU-002',
    );
    await pumpUi(tester);

    expect(find.text('Receive Item'), findsOneWidget);
    expect(
      find.byKey(const Key('inbound-receipt-detail-barcode-field')),
      findsNothing,
    );

    final quantityField = tester.widget<TextField>(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
    );
    expect(quantityField.enabled, isTrue);
  });

  testWidgets('receipt detail confirms quantity and updates the list',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
      'SKU-002',
    );
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
      '5',
    );
    await tester.tap(
      find.byKey(const Key('inbound-receipt-detail-confirm-button')),
    );
    await pumpUi(tester);

    expect(find.text('Red Mug'), findsOneWidget);
    expect(find.text('5 received'), findsOneWidget);
  });

  testWidgets('matching quantity turns the receipt row green', (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
      'SKU-001',
    );
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
      '4',
    );
    await tester.tap(
      find.byKey(const Key('inbound-receipt-detail-confirm-button')),
    );
    await pumpUi(tester);

    final container = tester.widget<Ink>(
      find.byKey(const Key('inbound-receipt-item-container-item-1')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFE7F6EC));
  });

  testWidgets('mismatched quantity keeps the receipt row non-green',
      (tester) async {
    await tester.pumpWidget(
      buildReceiptPage(
        repository: buildRepository(),
        receiptId: 'receipt-1001',
        initialScanResult: buildScanResult(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(const Key('inbound-receipt-start-button')));
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-hidden-scan-field')),
      'SKU-002',
    );
    await pumpUi(tester);

    await tester.enterText(
      find.byKey(const Key('inbound-receipt-detail-quantity-field')),
      '5',
    );
    await tester.tap(
      find.byKey(const Key('inbound-receipt-detail-confirm-button')),
    );
    await pumpUi(tester);

    final container = tester.widget<Ink>(
      find.byKey(const Key('inbound-receipt-item-container-item-2')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, isNot(const Color(0xFFE7F6EC)));
  });
}
