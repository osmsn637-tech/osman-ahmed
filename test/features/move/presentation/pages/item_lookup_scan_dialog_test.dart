import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wherehouse/features/move/presentation/pages/item_lookup_scan_dialog.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';

void main() {
  Finder confirmButtonFinder() => find.descendant(
        of: find.byKey(const Key('lookup_manual_confirm_button')),
        matching: find.byType(FilledButton),
      );

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

    final fieldFinder = find.byKey(const Key('scan_barcode_field'));
    final textField = tester.widget<TextField>(fieldFinder);
    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    final fieldSize = tester.getSize(fieldFinder);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Scan or enter barcode'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsNothing);
    expect(textField.readOnly, isFalse);
    expect(textField.autofocus, isTrue);
    expect(textField.keyboardType, TextInputType.none);
    expect(editableText.focusNode.hasFocus, isTrue);
    expect(fieldSize.width, greaterThan(0));
    expect(fieldSize.height, greaterThan(0));
  });

  testWidgets(
      'manual keypad mode does not trigger an additional soft keyboard open', (
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

    final initialShowCount =
        calls.where((call) => call.method == 'TextInput.show').length;

    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pump();

    final showCountAfterManualTap =
        calls.where((call) => call.method == 'TextInput.show').length;
    expect(showCountAfterManualTap, initialShowCount);
  });

  testWidgets('manual mode opens a dark-blue keypad and waits for confirm', (
    tester,
  ) async {
    String? result;

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
                onPressed: () async {
                  result = await showItemLookupScanDialog(
                    context,
                    showKeyboard: false,
                  );
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

    expect(find.byKey(const Key('lookup_manual_keypad')), findsNothing);

    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookup_manual_keypad')), findsOneWidget);

    final dialogCard = tester.widget<DecoratedBox>(
      find.byKey(const Key('lookup_dialog_card')),
    );
    final cardDecoration = dialogCard.decoration as BoxDecoration;
    expect(cardDecoration.color, AppTheme.primary);

    final digit1 =
        tester.getCenter(find.byKey(const Key('lookup_manual_digit_1')));
    final digit2 =
        tester.getCenter(find.byKey(const Key('lookup_manual_digit_2')));
    final digit3 =
        tester.getCenter(find.byKey(const Key('lookup_manual_digit_3')));
    final digit4 =
        tester.getCenter(find.byKey(const Key('lookup_manual_digit_4')));

    expect(digit1.dy, moreOrLessEquals(digit2.dy, epsilon: 1));
    expect(digit2.dy, moreOrLessEquals(digit3.dy, epsilon: 1));
    expect(digit1.dy, isNot(moreOrLessEquals(digit4.dy, epsilon: 1)));

    final confirmBeforeDigits = tester.widget<FilledButton>(
      confirmButtonFinder(),
    );
    expect(confirmBeforeDigits.onPressed, isNull);

    await tester.tap(find.byKey(const Key('lookup_manual_digit_1')));
    await tester.tap(find.byKey(const Key('lookup_manual_digit_2')));
    await tester.tap(find.byKey(const Key('lookup_manual_digit_3')));
    await tester.pump();

    expect(result, isNull);
    expect(find.byType(Dialog), findsOneWidget);

    final confirmAfterDigits = tester.widget<FilledButton>(
      confirmButtonFinder(),
    );
    expect(confirmAfterDigits.onPressed, isNotNull);

    await tester.ensureVisible(confirmButtonFinder());
    await tester.tap(confirmButtonFinder());
    await tester.pumpAndSettle();

    expect(result, '123');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('keypad action labels fit on a narrow width without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openDialog(tester);
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'manual keypad bottom row keeps 0 larger and side buttons symmetric', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    final deleteFinder = find.byKey(const Key('lookup_manual_delete_button'));
    final zeroFinder = find.byKey(const Key('lookup_manual_digit_0'));
    final confirmFinder = find.byKey(const Key('lookup_manual_confirm_button'));

    final deleteRect = tester.getRect(deleteFinder);
    final zeroRect = tester.getRect(zeroFinder);
    final confirmRect = tester.getRect(confirmFinder);

    expect(zeroRect.width, greaterThan(deleteRect.width));
    expect(zeroRect.width, greaterThan(confirmRect.width));
    expect(deleteRect.width, moreOrLessEquals(confirmRect.width, epsilon: 1));
    expect(deleteRect.top, moreOrLessEquals(zeroRect.top, epsilon: 1));
    expect(zeroRect.top, moreOrLessEquals(confirmRect.top, epsilon: 1));
  });

  testWidgets('manual keypad hides scan-mode sections while open', (
    tester,
  ) async {
    await openDialog(tester);

    expect(find.text('Hidden scanner input is active'), findsOneWidget);
    expect(find.byKey(const Key('lookup_manual_entry_button')), findsOneWidget);
    expect(find.byKey(const Key('lookup_manual_cancel_button')), findsNothing);

    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Hidden scanner input is active'), findsNothing);
    expect(find.byKey(const Key('lookup_manual_entry_button')), findsNothing);
    expect(find.byKey(const Key('lookup_manual_cancel_button')), findsNothing);
    expect(find.byKey(const Key('lookup_manual_keypad')), findsOneWidget);
  });
}
