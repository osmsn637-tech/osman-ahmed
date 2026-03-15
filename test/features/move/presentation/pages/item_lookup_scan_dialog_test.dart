import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:putaway_app/features/move/presentation/pages/item_lookup_scan_dialog.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showItemLookupScanDialog(context, showKeyboard: false);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('scanner mode keeps the barcode field ready for scan capture', (
    tester,
  ) async {
    await openDialog(tester);

    final textField = tester.widget<TextField>(
      find.byKey(const Key('scan_barcode_field')),
    );
    final editableText = tester.widget<EditableText>(find.byType(EditableText));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Enter manually'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsNothing);
    expect(textField.readOnly, isFalse);
    expect(textField.keyboardType, TextInputType.visiblePassword);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'scanner mode does not open soft keyboard until manual entry is tapped', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      );
    });

    await openDialog(tester);

    expect(calls.where((call) => call.method == 'TextInput.show'), isEmpty);

    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pump();

    expect(calls.any((call) => call.method == 'TextInput.show'), isTrue);
  });
}
