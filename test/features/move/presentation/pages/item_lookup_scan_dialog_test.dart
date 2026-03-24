import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wherehouse/features/move/presentation/pages/item_lookup_scan_dialog.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';

void main() {
  Finder scannerFieldFinder() => find.descendant(
        of: find.byKey(const Key('scan_barcode_field')),
        matching: find.byType(EditableText),
      );

  Finder confirmButtonFinder() => find.descendant(
        of: find.byKey(const Key('lookup_manual_confirm_button')),
        matching: find.byType(FilledButton),
      );

  Future<void> openDialog(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
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

    final fieldFinder = scannerFieldFinder();
    final editableText = tester.widget<EditableText>(fieldFinder);
    final fieldSize = tester.getSize(fieldFinder);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Scan or enter barcode'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsNothing);
    expect(editableText.autofocus, isTrue);
    expect(editableText.focusNode.hasFocus, isTrue);
    expect(fieldSize.width, greaterThan(0));
    expect(fieldSize.height, greaterThan(0));
    expect(find.byKey(const Key('lookup_scanner_status_label')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('lookup_scanner_status_label')))
          .data,
      'Scanner focus active',
    );
    expect(find.byKey(const Key('lookup_reconnect_button')), findsOneWidget);
  });

  testWidgets('tapping the popup re-focuses the scanner field', (tester) async {
    await openDialog(tester);

    final fieldFinder = scannerFieldFinder();
    var editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);

    editableText.focusNode.unfocus();
    await tester.pump();
    editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isFalse);

    await tester.tap(find.byKey(const Key('lookup_dialog_card')));
    await tester.pump();
    await tester.pump();

    editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('popup scanner focus survives an app-level unfocus tap wrapper',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child ?? const SizedBox.shrink(),
        ),
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

    final fieldFinder = scannerFieldFinder();
    var editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);

    editableText.focusNode.unfocus();
    await tester.pump();

    await tester.tap(find.byKey(const Key('lookup_dialog_card')));
    await tester.pump();
    await tester.pump();

    editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('scanner field re-focuses automatically every second',
      (tester) async {
    await openDialog(tester);

    final fieldFinder = scannerFieldFinder();
    var editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);

    editableText.focusNode.unfocus();
    await tester.pump();
    editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isFalse);

    await tester.pump(const Duration(seconds: 1));

    editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'auto focus refresh does not rebuild the scanner field while it is already focused and idle',
      (tester) async {
    await openDialog(tester);

    final fieldFinder = scannerFieldFinder();
    final firstEditableText = tester.widget<EditableText>(fieldFinder);
    final firstFocusNode = firstEditableText.focusNode;

    expect(firstFocusNode.hasFocus, isTrue);

    await tester.pump(const Duration(seconds: 1));

    final secondEditableText = tester.widget<EditableText>(fieldFinder);
    expect(secondEditableText.focusNode, same(firstFocusNode));
    expect(secondEditableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('app resume keeps the hidden scanner field ready for scanning',
      (tester) async {
    await openDialog(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    final fieldFinder = scannerFieldFinder();
    final editableText = tester.widget<EditableText>(fieldFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'app resume primes the scanner input method for the popup',
      (tester) async {
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
    final firstEditableText = tester.widget<EditableText>(scannerFieldFinder());
    final firstFocusNode = firstEditableText.focusNode;
    calls.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final secondEditableText = tester.widget<EditableText>(scannerFieldFinder());
    expect(secondEditableText.focusNode, isNot(same(firstFocusNode)));
    final showCalls = calls.where((call) => call.method == 'TextInput.show').length;
    final hideCalls = calls.where((call) => call.method == 'TextInput.hide').length;
    expect(showCalls, greaterThan(0));
    expect(hideCalls, greaterThan(0));
  });

  testWidgets(
      'first popup open after app resume primes the scanner input method',
      (tester) async {
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    calls.clear();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final showCalls = calls.where((call) => call.method == 'TextInput.show').length;
    final hideCalls = calls.where((call) => call.method == 'TextInput.hide').length;
    expect(showCalls, greaterThan(0));
    expect(hideCalls, greaterThan(0));
  });

  testWidgets(
      'first popup open after app resume performs a delayed scanner reattach',
      (tester) async {
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final firstEditableText = tester.widget<EditableText>(scannerFieldFinder());
    final firstFocusNode = firstEditableText.focusNode;

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    final secondEditableText = tester.widget<EditableText>(scannerFieldFinder());
    expect(secondEditableText.focusNode, isNot(same(firstFocusNode)));
    expect(secondEditableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('reopening the dialog creates a fresh active scanner focus node',
      (tester) async {
    await openDialog(tester);

    final firstFieldFinder = scannerFieldFinder();
    final firstEditableText = tester.widget<EditableText>(firstFieldFinder);
    final firstFocusNode = firstEditableText.focusNode;

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final secondFieldFinder = scannerFieldFinder();
    final secondEditableText = tester.widget<EditableText>(secondFieldFinder);

    expect(secondEditableText.focusNode, isNot(same(firstFocusNode)));
    expect(secondEditableText.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'arabic lookup popup shows readable text instead of question marks',
      (tester) async {
    await openDialog(tester, locale: const Locale('ar'));

    expect(find.text('امسح الباركود'), findsOneWidget);
    expect(find.text('تركيز الماسح نشط'), findsOneWidget);
    expect(find.text('بانتظار مسح الباركود'), findsOneWidget);
    expect(find.text('إدخال يدوي'), findsOneWidget);
    expect(find.text('????'), findsNothing);
  });

  testWidgets('manual mode opens a system numeric text field', (tester) async {
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

    await tester.ensureVisible(
      find.byKey(const Key('lookup_manual_entry_button')),
    );
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookup_manual_text_field')), findsOneWidget);

    final textField = tester.widget<TextField>(
      find.byKey(const Key('lookup_manual_text_field')),
    );
    expect(textField.keyboardType, TextInputType.number);

    final showCount =
        calls.where((call) => call.method == 'TextInput.show').length;
    expect(showCount, greaterThan(0));
  });

  testWidgets('manual mode accepts typed digits and waits for confirm', (
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

    expect(find.byKey(const Key('lookup_manual_text_field')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('lookup_manual_entry_button')),
    );
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookup_manual_text_field')), findsOneWidget);

    final dialogCard = tester.widget<DecoratedBox>(
      find.byKey(const Key('lookup_dialog_card')),
    );
    final cardDecoration = dialogCard.decoration as BoxDecoration;
    expect(cardDecoration.color, AppTheme.primary);

    final confirmBeforeDigits = tester.widget<FilledButton>(
      confirmButtonFinder(),
    );
    expect(confirmBeforeDigits.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('lookup_manual_text_field')),
      '123',
    );
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

  testWidgets('manual entry actions fit on a narrow width without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openDialog(tester);
    await tester.ensureVisible(
      find.byKey(const Key('lookup_manual_entry_button')),
    );
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual entry can be cancelled back to scan mode', (tester) async {
    await openDialog(tester);
    await tester.ensureVisible(
      find.byKey(const Key('lookup_manual_entry_button')),
    );
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookup_manual_text_field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lookup_manual_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookup_manual_text_field')), findsNothing);
    expect(find.text('Scanner focus active'), findsOneWidget);
  });

  testWidgets('manual entry hides scan-mode sections while open', (
    tester,
  ) async {
    await openDialog(tester);

    expect(find.text('Scanner focus active'), findsOneWidget);
    expect(find.byKey(const Key('lookup_manual_entry_button')), findsOneWidget);
    expect(find.byKey(const Key('lookup_manual_cancel_button')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('lookup_manual_entry_button')),
    );
    await tester.tap(find.byKey(const Key('lookup_manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Scanner focus active'), findsNothing);
    expect(find.byKey(const Key('lookup_manual_entry_button')), findsNothing);
    expect(find.byKey(const Key('lookup_manual_cancel_button')), findsOneWidget);
    expect(find.byKey(const Key('lookup_manual_text_field')), findsOneWidget);
  });

  testWidgets('reconnect button rebuilds scanner attachment', (tester) async {
    await openDialog(tester);

    final fieldFinder = scannerFieldFinder();
    final firstEditableText = tester.widget<EditableText>(fieldFinder);
    final firstFocusNode = firstEditableText.focusNode;

    final reconnectButton = tester.widget<IconButton>(
      find.byKey(const Key('lookup_reconnect_button')),
    );
    reconnectButton.onPressed!.call();
    await tester.pump();
    await tester.pump();

    final secondEditableText = tester.widget<EditableText>(fieldFinder);
    expect(secondEditableText.focusNode, isNot(same(firstFocusNode)));
    expect(secondEditableText.focusNode.hasFocus, isTrue);
  });
}
