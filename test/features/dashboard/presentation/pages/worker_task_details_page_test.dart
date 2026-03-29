import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/app_exception.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:wherehouse/features/dashboard/domain/entities/task_entity.dart';
import 'package:wherehouse/features/dashboard/presentation/pages/worker_task_details_page.dart';
import 'package:wherehouse/features/dashboard/presentation/shared/task_report_photo_attachment.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_entity.dart';
import 'package:wherehouse/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';

void main() {
  final samplePngBytes = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x03,
    0x01,
    0x01,
    0x00,
    0x18,
    0xDD,
    0x8D,
    0xB1,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  Widget wrap(Widget child, {Locale? locale}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  TaskEntity buildTask({
    TaskType type = TaskType.move,
    String? remoteTaskId,
    String? apiTaskType,
    String? itemBarcode = '123456789012',
    String? itemImageUrl = 'https://example.com/item.png',
    String? fromLocation = 'Z01-C01-L01-P01',
    String? toLocation = 'Z01-BLK-C01-L01-P01',
    String? toLocationId,
    int quantity = 12,
    String? unit,
    TaskStatus status = TaskStatus.inProgress,
    String? assignedTo = '2bcf9d5d-1234-4f1d-8f6d-000000000007',
    Map<String, Object?>? workflowData,
  }) {
    return TaskEntity(
      id: 1,
      remoteTaskId: remoteTaskId,
      apiTaskType: apiTaskType,
      type: type,
      itemId: 1001,
      itemName: 'Demo Item',
      fromLocation: fromLocation,
      toLocation: toLocation,
      toLocationId: toLocationId,
      quantity: quantity,
      unit: unit,
      assignedTo: assignedTo,
      status: status,
      createdBy: 'system',
      zone: 'Z01',
      itemBarcode: itemBarcode,
      itemImageUrl: itemImageUrl,
      workflowData: workflowData ?? const <String, Object?>{},
    );
  }

  ItemLocationSummaryEntity buildLookupSummary() {
    return const ItemLocationSummaryEntity(
      itemId: 1001,
      itemName: 'Demo Item',
      barcode: '123456789012',
      itemImageUrl: 'https://example.com/lookup-item.png',
      totalQuantity: 12,
      locations: [
        ItemLocationEntity(
          locationId: 1,
          zone: 'Z01',
          type: 'bulk',
          code: 'BULK-01-01',
          quantity: 20,
        ),
        ItemLocationEntity(
          locationId: 2,
          zone: 'Z01',
          type: 'shelf',
          code: 'SHELF-01-01',
          quantity: 8,
        ),
      ],
    );
  }

  bool isElevatedButtonEnabled(WidgetTester tester, Key key) {
    final button = tester.widget<ElevatedButton>(find.byKey(key));
    return button.onPressed != null;
  }

  Color? elevatedButtonBackground(WidgetTester tester, Key key) {
    final button = tester.widget<ElevatedButton>(find.byKey(key));
    return button.style?.backgroundColor?.resolve({});
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterLocationManually(
    WidgetTester tester,
    String value,
  ) async {
    final manualButton = find.byKey(const Key('manual-type-location-button'));
    await scrollTo(tester, manualButton);
    await tester.tap(manualButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual-location-dialog-field')),
      value,
    );
    await tester.tap(find.byKey(const Key('manual-location-submit')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  Future<void> openBarcodeKeypad(WidgetTester tester) async {
    final manualButton = find.byKey(const Key('manual-type-barcode-button'));
    await scrollTo(tester, manualButton);
    await tester.tap(manualButton);
    await tester.pumpAndSettle();
  }

  Future<void> enterScannerValue(
    WidgetTester tester,
    Key key,
    String value,
  ) async {
    await tester.enterText(find.byKey(key), value);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('renders item name and barcode text only', (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    expect(find.text('Demo Item'), findsWidgets);
    expect(find.text('123456789012'), findsOneWidget);
  });

  testWidgets('generic task hero shows labeled quantity summary',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    final quantitySummary = find.byKey(const Key('task-hero-quantity-summary'));

    expect(quantitySummary, findsOneWidget);
    expect(
      find.descendant(of: quantitySummary, matching: find.text('Quantity')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: quantitySummary, matching: find.text('12 pc')),
      findsOneWidget,
    );
  });

  testWidgets('generic task hero shows labeled quantity summary with unit',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(quantity: 12, unit: 'box'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quantitySummary = find.byKey(const Key('task-hero-quantity-summary'));

    expect(quantitySummary, findsOneWidget);
    expect(
      find.descendant(of: quantitySummary, matching: find.text('12 box')),
      findsOneWidget,
    );
  });

  testWidgets('shows mapped completion error message when complete fails',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            throw const ValidationException('complete endpoint rejected');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('cycle-count-hidden-scan-field'),
      '123456789012',
    );

    await tester.enterText(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
      '10',
    );
    await tester
        .tap(find.byKey(const Key('cycle-count-detail-confirm-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('complete endpoint rejected'), findsOneWidget);
  });

  testWidgets(
      'return task renders return validation flow without raw enum text',
      (tester) async {
    await tester.pumpWidget(
      wrap(WorkerTaskDetailsPage(task: buildTask(type: TaskType.returnTask))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Return Tote'), findsOneWidget);
    expect(find.text('RETURNTASK'), findsNothing);
  });

  testWidgets('renders from and to locations with shelf/bulk labels',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('From (Shelf)'));

    expect(find.text('From (Shelf)'), findsOneWidget);
    expect(find.text('Z01-C01-L01-P01'), findsOneWidget);
    expect(find.text('To (Bulk)'), findsOneWidget);
    expect(find.text('Z01-BLK-C01-L01-P01'), findsWidgets);
  });

  testWidgets('renders fallback states for missing barcode and image',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(itemBarcode: null, itemImageUrl: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No barcode available'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('auto-validates product barcode and location values',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );
    expect(find.text('Product validated'), findsOneWidget);
    expect(find.byKey(const Key('validate-product-button')), findsNothing);

    await enterLocationManually(tester, 'Z01-C99-L99-P99');
    await tester.pumpAndSettle();
    expect(find.text('Location mismatch'), findsOneWidget);
    expect(find.byKey(const Key('validate-location-button')), findsNothing);
  });

  testWidgets(
      'receive flow shows next-step guidance and advances after product validation',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(type: TaskType.receive, fromLocation: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nextStepCard = find.byKey(const Key('task-next-step-card'));
    expect(nextStepCard, findsOneWidget);
    expect(
      find.descendant(of: nextStepCard, matching: find.text('Next step')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: nextStepCard,
        matching: find.text('Scan product barcode'),
      ),
      findsOneWidget,
    );

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(
      find.descendant(
        of: nextStepCard,
        matching: find.text('Scan bulk location'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows manual type actions for barcode and location validation',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual-type-barcode-button')), findsOneWidget);
    expect(find.text('Manual Type'), findsWidgets);
  });

  testWidgets('opens report problem dialog from task details', (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-task-dialog')), findsOneWidget);
    expect(find.byKey(const Key('report-task-note-field')), findsOneWidget);
    expect(find.byKey(const Key('report-task-photo-button')), findsOneWidget);
    expect(find.byKey(const Key('report-task-submit-button')), findsOneWidget);
  });

  testWidgets('report dialog keeps submit disabled until note is entered',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();

    final disabledButton = tester.widget<FilledButton>(
      find.byKey(const Key('report-task-submit-button')),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('report-task-note-field')),
      'Damaged shelf label',
    );
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const Key('report-task-submit-button')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('submits report note from the dialog', (tester) async {
    String? submittedNote;
    String? submittedPhotoPath;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {
            submittedNote = note;
            submittedPhotoPath = photoPath;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-task-note-field')),
      'Broken tote on shelf',
    );
    await tester.pumpAndSettle();
    final submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('report-task-submit-button')),
    );
    submitButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(submittedNote, 'Broken tote on shelf');
    expect(submittedPhotoPath, isNull);
    expect(find.text('Problem report sent successfully.'), findsOneWidget);
  });

  testWidgets('shows selected report photo preview before submit',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {},
          onCaptureReportPhoto: () async => TaskReportPhotoAttachment(
            path: 'C:/tmp/report-photo.jpg',
            bytes: samplePngBytes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();
    final photoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('report-task-photo-button')),
    );
    photoButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-task-photo-preview')), findsOneWidget);
    expect(find.byKey(const Key('report-task-remove-photo-button')),
        findsOneWidget);
  });

  testWidgets('keeps report dialog open and shows error when submit fails',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {
            throw const ValidationException('report rejected');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-task-note-field')),
      'Printer issue',
    );
    await tester.pumpAndSettle();
    final submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('report-task-submit-button')),
    );
    submitButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-task-dialog')), findsOneWidget);
    expect(find.text('report rejected'), findsOneWidget);
  });

  testWidgets('manual barcode dialog uses a fixed 3x3 keypad grid',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await openBarcodeKeypad(tester);

    expect(find.byKey(const Key('manual-barcode-dialog')), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    for (final digit in <String>['1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      expect(find.byKey(Key('manual-barcode-digit-$digit')), findsOneWidget);
    }
    expect(find.byKey(const Key('manual-barcode-delete')), findsOneWidget);
    expect(find.byKey(const Key('manual-barcode-digit-0')), findsOneWidget);
    expect(find.byKey(const Key('manual-barcode-submit')), findsOneWidget);
  });

  testWidgets('shows start action and triggers callback for pending task',
      (tester) async {
    var started = false;
    final task = buildTask(status: TaskStatus.pending, assignedTo: null);

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: task,
          onStartTask: () async {
            started = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-task-button')));
    await tester.pumpAndSettle();

    expect(started, isTrue);
  });

  testWidgets('starting a pending task keeps the details page open',
      (tester) async {
    final task = buildTask(status: TaskStatus.pending, assignedTo: null);

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: task,
          onStartTask: () async {},
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Task Details'), findsOneWidget);
    expect(find.byKey(const Key('start-task-button')), findsNothing);
    expect(find.byKey(const Key('complete-task-button')), findsOneWidget);
  });

  testWidgets('uses dark blue for the start task button', (tester) async {
    final task = buildTask(status: TaskStatus.pending, assignedTo: null);

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: task,
          onStartTask: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      elevatedButtonBackground(tester, const Key('start-task-button')),
      AppTheme.primary,
    );
  });

  testWidgets(
      'pending receive task shows right product and stays on page one before start',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.receive,
            status: TaskStatus.pending,
            assignedTo: null,
            fromLocation: null,
            toLocation: 'BULK-01-02',
          ),
          onStartTask: () async {},
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-task-button')), findsOneWidget);
    expect(find.text('Bulk Location'), findsNothing);
    expect(find.byKey(const Key('location-validate-field')), findsNothing);

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(find.text('right product'), findsOneWidget);
    expect(find.byKey(const Key('start-task-button')), findsOneWidget);
    expect(find.byKey(const Key('complete-task-button')), findsNothing);
    expect(find.text('Bulk Location'), findsNothing);
    expect(find.byKey(const Key('location-validate-field')), findsNothing);
  });

  testWidgets('failed start keeps the task in pending state', (tester) async {
    var startAttempts = 0;
    final task = buildTask(status: TaskStatus.pending, assignedTo: null);

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: task,
          onStartTask: () async {
            startAttempts += 1;
            throw Exception('claim failed');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-task-button')));
    await tester.pumpAndSettle();

    expect(startAttempts, 1);
    expect(find.byKey(const Key('start-task-button')), findsOneWidget);
    expect(find.byKey(const Key('complete-task-button')), findsNothing);
    expect(find.text('Task Details'), findsOneWidget);
  });

  testWidgets('receive task shows inbound source and simplified item details',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.receive,
            fromLocation: null,
            toLocation: 'BULK-01-02',
          ),
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Demo Item'), findsOneWidget);
    expect(find.text('123456789012'), findsOneWidget);
    expect(find.text('12 pc'), findsOneWidget);
    expect(find.text('From Inbound'), findsOneWidget);
    expect(find.text('To Bulk Location'), findsNothing);
    expect(find.text('BULK-01-02'), findsNothing);
    expect(find.text('Task Info'), findsNothing);
    expect(find.byKey(const Key('receive-hero-card')), findsOneWidget);
    expect(find.byKey(const Key('receive-barcode-pill')), findsOneWidget);
    expect(find.byKey(const Key('receive-quantity-card')), findsOneWidget);
    expect(find.byKey(const Key('receive-item-image')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('receive-item-image'))).height,
        lessThan(184));
    expect(find.text('Item Image'), findsNothing);
    expect(find.text('Barcode'), findsNothing);
    expect(find.text('Locked'), findsNothing);
    expect(find.byIcon(Icons.looks_one_rounded), findsNothing);
    expect(find.byIcon(Icons.looks_two_rounded), findsNothing);
  });

  testWidgets(
      'receive task auto-opens page 2 after barcode validation and then allows bulk validation and completion',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.receive,
            fromLocation: null,
            toLocation: 'BULK-01-02',
          ),
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.byKey(const Key('location-validate-field')), findsNothing);
    expect(find.byKey(const Key('complete-task-button')), findsNothing);

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(find.text('Product validated'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Bulk Location'), findsOneWidget);
    expect(find.text('Locked'), findsNothing);
    expect(find.byIcon(Icons.looks_one_rounded), findsNothing);
    expect(find.byIcon(Icons.looks_two_rounded), findsNothing);
    expect(find.byKey(const Key('validate-product-button')), findsNothing);
    expect(find.byKey(const Key('validate-location-button')), findsNothing);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await enterLocationManually(tester, 'BULK-01-02');
    await tester.pumpAndSettle();

    expect(find.text('Location validated'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );
  });

  testWidgets(
      'putaway receive flow validates locally and completes with stored location id',
      (tester) async {
    var validateCalls = 0;
    String? completedLocation;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.receive,
            apiTaskType: 'putaway',
            fromLocation: null,
            toLocation: 'BULK-01-02',
            toLocationId: 'loc-77',
          ),
          onValidateLocation: (_) async {
            validateCalls += 1;
            return <String, dynamic>{'valid': true};
          },
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            completedLocation = locationId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    await enterLocationManually(tester, 'BULK-01-02');
    await tester.pumpAndSettle();

    expect(validateCalls, 0);
    expect(find.text('Location validated'), findsOneWidget);

    await scrollTo(tester, find.byKey(const Key('complete-task-button')));
    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedLocation, 'loc-77');
  });

  testWidgets('non-receive tasks keep the existing generic layout',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Movement'));

    expect(find.text('Movement'), findsOneWidget);
    expect(find.text('Task Info'), findsOneWidget);
    expect(find.text('From Inbound'), findsNothing);
    expect(find.byKey(const Key('validate-product-button')), findsNothing);
    expect(find.byKey(const Key('validate-location-button')), findsNothing);
  });

  testWidgets(
      'refill task preloads lookup data and requires barcode, shelf, and quantity before completion',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();
    var completedTaskId = 0;
    int? completedQuantity;
    String? completedLocation;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            completedTaskId = taskId;
            completedQuantity = quantity;
            completedLocation = locationId;
          },
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('From Bulk Location'), findsOneWidget);
    expect(find.text('BULK-01-01'), findsOneWidget);
    expect(find.byKey(const Key('refill-item-image')), findsOneWidget);
    expect(find.text('Locked'), findsNothing);
    expect(find.byIcon(Icons.looks_one_rounded), findsNothing);
    expect(find.byIcon(Icons.looks_two_rounded), findsNothing);

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(find.text('Page 2'), findsNothing);
    expect(find.text('To Shelf Location'), findsOneWidget);
    expect(find.text('SHELF-01-01'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );
    expect(find.byKey(const Key('validate-product-button')), findsNothing);
    expect(find.byKey(const Key('validate-location-button')), findsNothing);

    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('refill-quantity-field')));
    await tester.enterText(find.byKey(const Key('refill-quantity-field')), '4');
    await tester.pumpAndSettle();

    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await scrollTo(tester, find.byKey(const Key('complete-task-button')));
    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedTaskId, 1);
    expect(completedQuantity, 4);
    expect(completedLocation, 'SHELF-01-01');
  });

  testWidgets(
      'refill quantity field keeps focus instead of being reclaimed by the hidden scanner field',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
        ),
      ),
    );

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );
    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();

    final quantityField = find.byKey(const Key('refill-quantity-field'));
    final quantityEditable = find.descendant(
      of: quantityField,
      matching: find.byType(EditableText),
    );
    final locationEditable = find.descendant(
      of: find.byKey(const Key('location-validate-field')),
      matching: find.byType(EditableText),
    );

    await scrollTo(tester, quantityField);
    await tester.tap(quantityField);
    await tester.pump();

    var quantityText = tester.widget<EditableText>(quantityEditable);
    var locationText = tester.widget<EditableText>(locationEditable);

    expect(quantityText.focusNode.hasFocus, isTrue);
    expect(locationText.focusNode.hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    quantityText = tester.widget<EditableText>(quantityEditable);
    locationText = tester.widget<EditableText>(locationEditable);

    expect(quantityText.focusNode.hasFocus, isTrue);
    expect(locationText.focusNode.hasFocus, isFalse);
  });

  testWidgets('refill quantity field keeps the soft keyboard visible',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
        ),
      ),
    );

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );
    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();

    final quantityField = find.byKey(const Key('refill-quantity-field'));
    await scrollTo(tester, quantityField);
    await tester.tap(quantityField);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('refill manual location dialog keeps the soft keyboard visible',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
        ),
      ),
    );

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    final manualButton = find.byKey(const Key('manual-type-location-button'));
    await scrollTo(tester, manualButton);
    await tester.tap(manualButton);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('refill first page keeps barcode scanner focus after lookup loads',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
        ),
      ),
    );

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    final barcodeEditable = find.descendant(
      of: find.byKey(const Key('product-validate-field')),
      matching: find.byType(EditableText),
    );

    var barcodeText = tester.widget<EditableText>(barcodeEditable);
    expect(barcodeText.focusNode.hasFocus, isTrue);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    barcodeText = tester.widget<EditableText>(barcodeEditable);
    expect(barcodeText.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'assigned pending refill task advances after barcode scan and can complete',
      (tester) async {
    final lookupCompleter = Completer<ItemLocationSummaryEntity>();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            status: TaskStatus.pending,
            assignedTo: 'worker-1',
            fromLocation: null,
            toLocation: null,
          ),
          onLookupItem: (_) => lookupCompleter.future,
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );

    lookupCompleter.complete(buildLookupSummary());
    await tester.pumpAndSettle();

    final barcodeEditable = find.descendant(
      of: find.byKey(const Key('product-validate-field')),
      matching: find.byType(EditableText),
    );
    final barcodeText = tester.widget<EditableText>(barcodeEditable);
    expect(barcodeText.focusNode.hasFocus, isTrue);

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(find.text('To Shelf Location'), findsOneWidget);

    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('refill-quantity-field')));
    await tester.enterText(find.byKey(const Key('refill-quantity-field')), '4');
    await tester.pumpAndSettle();

    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );
  });

  testWidgets('refill task falls back to task locations when lookup fails',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.refill,
            fromLocation: 'BULK-02-01',
            toLocation: 'SHELF-02-09',
          ),
          onLookupItem: (_) async => throw Exception('lookup failed'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Could not load refill locations.'), findsNothing);
    expect(find.text('From Bulk Location'), findsOneWidget);
    expect(find.text('BULK-02-01'), findsOneWidget);
    expect(find.text('SHELF-02-09'), findsNothing);

    await enterScannerValue(
      tester,
      const Key('product-validate-field'),
      '123456789012',
    );

    expect(find.text('To Shelf Location'), findsOneWidget);
    expect(find.text('SHELF-02-09'), findsOneWidget);
  });

  testWidgets('auto-validates generic task location for manual entry',
      (tester) async {
    var validateCalls = 0;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onValidateLocation: (_) async {
            validateCalls += 1;
            return <String, dynamic>{'valid': true};
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterLocationManually(tester, 'Z01-BLK-C01-L01-P01');
    await tester.pumpAndSettle();

    expect(find.text('Location validated'), findsOneWidget);
    expect(validateCalls, greaterThanOrEqualTo(1));
  });

  testWidgets(
      'return task uses a two-page multi-item workflow before completion',
      (tester) async {
    int? completedQuantity;
    String? completedLocation;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.returnTask,
            fromLocation: 'RT-204',
            toLocation: 'RET-01-04',
            quantity: 7,
            workflowData: const {
              'returnContainerId': 'RT-204',
              'returnItems': [
                {
                  'itemName': 'Blue Mug',
                  'itemBarcode': '123456789101',
                  'quantity': 5,
                  'imageUrl': 'https://example.com/blue-mug.png',
                  'location': 'RET-01-04',
                },
                {
                  'itemName': 'Red Mug',
                  'itemBarcode': '123456789102',
                  'quantity': 2,
                  'imageUrl': 'https://example.com/red-mug.png',
                  'location': 'RET-01-05',
                },
              ],
            },
          ),
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            completedQuantity = quantity;
            completedLocation = locationId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Mug'), findsOneWidget);
    expect(find.text('Red Mug'), findsOneWidget);
    expect(find.text('123456789101'), findsOneWidget);
    expect(find.text('123456789102'), findsOneWidget);
    expect(find.byKey(const Key('return-page-next-button')), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('return-page-next-button')),
      isFalse,
    );

    await enterScannerValue(
      tester,
      const Key('return-validate-field'),
      '123456789101',
    );
    expect(find.byKey(const Key('return-page-next-button')), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('return-page-next-button')),
      isFalse,
    );

    await enterScannerValue(
      tester,
      const Key('return-validate-field'),
      '123456789102',
    );

    expect(find.byKey(const Key('return-page-next-button')), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('return-page-next-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('return-page-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('RET-01-04'), findsOneWidget);
    expect(find.text('RET-01-05'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await scrollTo(
      tester,
      find.byKey(const Key('return-line-0-scan-location-button')),
    );
    await tester
        .tap(find.byKey(const Key('return-line-0-scan-location-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('scan_barcode_field')), 'RET-01-04');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('return-line-0-quantity-field')),
      '5',
    );

    await scrollTo(
      tester,
      find.byKey(const Key('return-line-1-scan-location-button')),
    );
    await tester
        .tap(find.byKey(const Key('return-line-1-scan-location-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('scan_barcode_field')), 'RET-01-05');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('return-line-1-quantity-field')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedQuantity, 7);
    expect(completedLocation, 'RET-01-05');
  });

  testWidgets(
      'adjustment task scans a location, previews decrease math, submits quantity, and finishes',
      (tester) async {
    String? scannedBarcode;
    String? submittedAdjustmentItemId;
    int? submittedQuantity;
    var completed = false;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.adjustment,
            remoteTaskId: 'adjustment-1',
            itemBarcode: null,
            itemImageUrl: null,
            toLocation: 'Z01-A01',
            quantity: 1,
          ),
          onScanAdjustmentLocation: (barcode) async {
            scannedBarcode = barcode;
            return const AdjustmentTaskLocationScan(
              locationId: 'loc-77',
              locationCode: 'Z01-A01',
              products: [
                AdjustmentTaskProduct(
                  adjustmentItemId: 'adj-item-1',
                  productId: 'prod-1',
                  productName: 'Blue Mug',
                  productImage: 'https://example.com/blue-mug.png',
                  systemQuantity: 10,
                  counted: false,
                ),
                AdjustmentTaskProduct(
                  adjustmentItemId: 'adj-item-2',
                  productId: 'prod-2',
                  productName: 'Red Mug',
                  productImage: 'https://example.com/red-mug.png',
                  systemQuantity: 2,
                  counted: true,
                ),
              ],
            );
          },
          onSubmitAdjustmentCount: ({
            required adjustmentItemId,
            required quantity,
            String? notes,
          }) async {
            submittedAdjustmentItemId = adjustmentItemId;
            submittedQuantity = quantity;
          },
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            completed = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('complete-task-button')), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('adjustment-scan-location-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan_barcode_field')),
      'Z01-A01',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(scannedBarcode, 'Z01-A01');
    expect(find.text('Blue Mug'), findsOneWidget);
    expect(find.text('Red Mug'), findsOneWidget);
    expect(find.text('Counted'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adjustment-product-adj-item-1')));
    await tester.pumpAndSettle();

    expect(find.text('Current: 10 pc'), findsNWidgets(2));
    expect(find.text('New: 10 pc'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('adjustment-quantity-field')),
      '7',
    );
    await tester.pumpAndSettle();

    expect(find.text('New: 7 pc'), findsOneWidget);

    await scrollTo(tester, find.byKey(const Key('adjustment-submit-button')));
    await tester.tap(find.byKey(const Key('adjustment-submit-button')));
    await tester.pumpAndSettle();

    expect(submittedAdjustmentItemId, 'adj-item-1');
    expect(submittedQuantity, 7);
    expect(find.text('Counted'), findsNWidgets(2));
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets(
      'single-item cycle count uses scan-first two-page flow and completes after confirm',
      (tester) async {
    int? completedQuantity;
    String? completedLocation;
    Map<String, Object?>? savedProgress;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            quantity: 12,
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {
            completedQuantity = quantity;
            completedLocation = locationId;
          },
          onSaveCycleCountProgress: (taskId, {required progress}) async {
            savedProgress = progress;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cycle Count'), findsWidgets);
    expect(find.text('Counted Items'), findsOneWidget);
    expect(find.text('Demo Item'), findsWidgets);
    expect(find.byKey(const Key('cycle-count-continue-later-button')),
        findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await enterLocationManually(tester, 'SHELF-01-01');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
      '123456789012',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Count Item'), findsOneWidget);
    expect(find.text('Expected Quantity: 12'), findsNothing);
    expect(find.byKey(const Key('cycle-count-detail-barcode-field')),
        findsNothing);

    await tester.enterText(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
      '10',
    );
    await tester
        .tap(find.byKey(const Key('cycle-count-detail-confirm-button')));
    await tester.pumpAndSettle();

    expect(savedProgress, isNotNull);
    expect(find.text('10 pc counted'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedQuantity, 10);
    expect(completedLocation, 'SHELF-01-01');
  });

  testWidgets('cycle count scan capture field stays scanner friendly',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
    );

    expect(textField.keyboardType, TextInputType.none);
    expect(textField.readOnly, isFalse);
  });

  testWidgets(
      'cycle count shows shelf reference but starts with empty location input',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHELF-01-01'), findsOneWidget);

    final textField = tester.widget<TextField>(
      find.byKey(const Key('location-validate-field')),
    );
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('barcode validation capture field suppresses soft keyboard',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('product-validate-field')),
    );

    expect(textField.keyboardType, TextInputType.none);
    expect(textField.readOnly, isFalse);
    expect(textField.autofocus, isTrue);
  });

  testWidgets('barcode validation field re-focuses after losing scanner focus',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    final editableFinder = find.descendant(
      of: find.byKey(const Key('product-validate-field')),
      matching: find.byType(EditableText),
    );

    var editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isTrue);

    editableText.focusNode.unfocus();
    await tester.pump();

    editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    editableText = tester.widget<EditableText>(editableFinder);
    expect(editableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('failed product scan clears the hidden field after 2 seconds',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(type: TaskType.receive, fromLocation: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '999999999999',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Product mismatch'), findsOneWidget);

    var textField = tester.widget<TextField>(
      find.byKey(const Key('product-validate-field')),
    );
    expect(textField.controller?.text, '999999999999');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(
      find.byKey(const Key('product-validate-field')),
    );
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('wrong product scan shows the cleaner product alert card',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(type: TaskType.receive, fromLocation: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '999999999999',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final alert = find.byKey(const Key('product-validation-alert'));
    expect(alert, findsOneWidget);
    expect(
      find.descendant(of: alert, matching: find.text('Product mismatch')),
      findsOneWidget,
    );
  });

  testWidgets(
      'cycle count detail quantity stays locked until barcode is validated',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo Item').first);
    await tester.pumpAndSettle();

    var quantityField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
    );
    expect(quantityField.enabled, isFalse);

    await tester.enterText(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
      '123456789012',
    );
    await tester.pumpAndSettle();

    quantityField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
    );
    expect(quantityField.enabled, isTrue);
  });

  testWidgets(
      'cycle count detail barcode field stays scanner ready and clears after 2 seconds',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            toLocation: 'SHELF-01-01',
            workflowData: const {
              'cycleCountMode': 'single_item',
              'expectedQuantity': 12,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo Item').first);
    await tester.pumpAndSettle();

    var barcodeField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
    );
    expect(barcodeField.autofocus, isTrue);

    await tester.enterText(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
      '123456789012',
    );
    await tester.pumpAndSettle();

    var quantityField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
    );
    expect(quantityField.enabled, isTrue);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    barcodeField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
    );
    expect(barcodeField.controller?.text, isEmpty);

    quantityField = tester.widget<TextField>(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
    );
    expect(quantityField.enabled, isTrue);
  });

  testWidgets(
      'cycle count continue later restores progress and gates completion',
      (tester) async {
    Map<String, Object?>? savedProgress;

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            itemBarcode: null,
            itemImageUrl: null,
            toLocation: 'SHELF-09-03',
            quantity: 2,
            workflowData: const {
              'cycleCountMode': 'full_shelf',
              'expectedLines': [
                {
                  'itemName': 'Blue Mug',
                  'barcode': 'SKU-001',
                  'expectedQuantity': 4,
                },
                {
                  'itemName': 'Red Mug',
                  'barcode': 'SKU-002',
                  'expectedQuantity': 2,
                },
              ],
            },
          ),
          onSaveCycleCountProgress: (taskId, {required progress}) async {
            savedProgress = progress;
          },
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Counted Items'), findsOneWidget);
    expect(find.text('Blue Mug'), findsOneWidget);
    expect(find.text('Red Mug'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await enterLocationManually(tester, 'SHELF-09-03');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
      'SKU-001',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cycle-count-detail-quantity-field')),
      '5',
    );
    await tester
        .tap(find.byKey(const Key('cycle-count-detail-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 counted'), findsOneWidget);
    expect(savedProgress, isNotNull);
    await tester
        .tap(find.byKey(const Key('cycle-count-continue-later-button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            itemBarcode: null,
            itemImageUrl: null,
            toLocation: 'SHELF-09-03',
            quantity: 2,
            workflowData: {
              'cycleCountMode': 'full_shelf',
              'expectedLines': const [
                {
                  'itemName': 'Blue Mug',
                  'barcode': 'SKU-001',
                  'expectedQuantity': 4,
                },
                {
                  'itemName': 'Red Mug',
                  'barcode': 'SKU-002',
                  'expectedQuantity': 2,
                },
              ],
              'cycleCountProgress': savedProgress,
            },
          ),
          onSaveCycleCountProgress: (taskId, {required progress}) async {
            savedProgress = progress;
          },
          onCompleteTask: (taskId,
              {cycleCountItems, quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 pc counted'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );
  });

  testWidgets(
      'restores saved cycle-count validated location without lifecycle error',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            itemBarcode: null,
            itemImageUrl: null,
            toLocation: 'SHELF-09-03',
            quantity: 2,
            workflowData: const {
              'cycleCountMode': 'full_shelf',
              'expectedLines': [
                {
                  'itemName': 'Blue Mug',
                  'barcode': 'SKU-001',
                  'expectedQuantity': 4,
                },
                {
                  'itemName': 'Red Mug',
                  'barcode': 'SKU-002',
                  'expectedQuantity': 2,
                },
              ],
              'cycleCountProgress': {
                'location': 'SHELF-09-03',
                'locationValidated': true,
              },
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
      findsOneWidget,
    );
    expect(find.text('Location validated'), findsOneWidget);
  });

  testWidgets(
      'full-shelf cycle count scan opens detail without manual barcode entry',
      (tester) async {
    final scannedBarcodes = <String>[];

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(
            type: TaskType.cycleCount,
            itemBarcode: null,
            itemImageUrl: null,
            toLocation: 'SHELF-09-03',
            quantity: 2,
            workflowData: const {
              'cycleCountMode': 'full_shelf',
              'expectedLines': [
                {
                  'itemName': 'Blue Mug',
                  'barcode': 'SKU-001',
                  'expectedQuantity': 4,
                },
                {
                  'itemName': 'Red Mug',
                  'barcode': 'SKU-002',
                  'expectedQuantity': 2,
                },
              ],
            },
          ),
          onValidateLocation: (barcode) async {
            scannedBarcodes.add(barcode);
            return <String, dynamic>{'valid': true};
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterLocationManually(tester, 'SHELF-09-03');
    await tester.pumpAndSettle();

    expect(scannedBarcodes, <String>['SHELF-09-03']);

    await tester.enterText(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
      'SKU-001',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(scannedBarcodes, <String>['SHELF-09-03']);
    expect(find.text('Count Item'), findsOneWidget);
    expect(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
      findsNothing,
    );
    expect(find.byKey(const Key('cycle-count-detail-quantity-field')),
        findsOneWidget);
  });

  testWidgets('task details renders Arabic labels', (tester) async {
    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: buildTask(),
          onReportTaskIssue: ({required note, photoPath}) async {},
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدخال يدوي'), findsWidgets);
    expect(find.text('الكمية'), findsWidgets);

    await tester.tap(find.byKey(const Key('report-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('الإبلاغ عن مشكلة'), findsWidgets);
    expect(find.text('ملاحظة'), findsOneWidget);
    expect(find.text('إرسال البلاغ'), findsOneWidget);
  });
}
