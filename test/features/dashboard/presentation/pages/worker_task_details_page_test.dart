import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:putaway_app/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';
import 'package:putaway_app/features/dashboard/presentation/pages/worker_task_details_page.dart';
import 'package:putaway_app/features/move/domain/entities/item_location_entity.dart';
import 'package:putaway_app/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:putaway_app/shared/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
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
    String? itemBarcode = '123456789012',
    String? itemImageUrl = 'https://example.com/item.png',
    String? fromLocation = 'Z01-C01-L01-P01',
    String? toLocation = 'Z01-BLK-C01-L01-P01',
    int quantity = 12,
    TaskStatus status = TaskStatus.inProgress,
    String? assignedTo = '2bcf9d5d-1234-4f1d-8f6d-000000000007',
    Map<String, Object?>? workflowData,
  }) {
    return TaskEntity(
      id: 1,
      remoteTaskId: remoteTaskId,
      type: type,
      itemId: 1001,
      itemName: 'Demo Item',
      fromLocation: fromLocation,
      toLocation: toLocation,
      quantity: quantity,
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

  bool isOutlinedButtonEnabled(WidgetTester tester, Key key) {
    final button = tester.widget<OutlinedButton>(find.byKey(key));
    return button.onPressed != null;
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

  testWidgets('renders item name and barcode text only', (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    expect(find.text('Demo Item'), findsWidgets);
    expect(find.text('123456789012'), findsOneWidget);
  });

  testWidgets('generic task hero shows labeled quantity summary', (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    final quantitySummary = find.byKey(const Key('task-hero-quantity-summary'));

    expect(quantitySummary, findsOneWidget);
    expect(
      find.descendant(of: quantitySummary, matching: find.text('Quantity')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: quantitySummary, matching: find.text('12')),
      findsOneWidget,
    );
  });

  testWidgets('shows normalized return task label', (tester) async {
    await tester.pumpWidget(
      wrap(WorkerTaskDetailsPage(task: buildTask(type: TaskType.returnTask))),
    );
    await tester.pumpAndSettle();

    expect(find.text('RETURN'), findsWidgets);
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

  testWidgets('validates product barcode and location values', (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('product-validate-field')), '123456789012');
    await scrollTo(tester, find.byKey(const Key('validate-product-button')));
    await tester.tap(find.byKey(const Key('validate-product-button')));
    await tester.pumpAndSettle();
    expect(find.text('Product validated'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('location-validate-field')), 'Z01-C99-L99-P99');
    final validateLocationButton =
        find.byKey(const Key('validate-location-button'));
    await scrollTo(tester, validateLocationButton);
    await tester.tap(validateLocationButton);
    await tester.pumpAndSettle();
    expect(find.text('Location mismatch'), findsOneWidget);
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
          onCompleteTask: (taskId, {quantity, locationId}) async {},
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

  testWidgets('shows a visible error when starting a task fails',
      (tester) async {
    final task = buildTask(status: TaskStatus.pending, assignedTo: null);

    await tester.pumpWidget(
      wrap(
        WorkerTaskDetailsPage(
          task: task,
          onStartTask: () async {
            throw Exception('claim failed');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-task-button')));
    await tester.pumpAndSettle();

    expect(
        find.text('Failed to start task. Please try again.'), findsOneWidget);
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
          onCompleteTask: (taskId, {quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Demo Item'), findsOneWidget);
    expect(find.text('123456789012'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
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
          onCompleteTask: (taskId, {quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.byKey(const Key('location-validate-field')), findsNothing);
    expect(find.byKey(const Key('complete-task-button')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '123456789012',
    );
    await scrollTo(tester, find.byKey(const Key('validate-product-button')));
    await tester.tap(find.byKey(const Key('validate-product-button')));
    await tester.pumpAndSettle();

    expect(find.text('Product validated'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Bulk Location'), findsOneWidget);
    expect(find.text('Locked'), findsNothing);
    expect(find.byIcon(Icons.looks_one_rounded), findsNothing);
    expect(find.byIcon(Icons.looks_two_rounded), findsNothing);
    expect(
      isOutlinedButtonEnabled(tester, const Key('validate-location-button')),
      isTrue,
    );
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('location-validate-field')),
      'BULK-01-02',
    );
    await tester.tap(find.byKey(const Key('validate-location-button')));
    await tester.pumpAndSettle();

    expect(find.text('Location validated'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );
  });

  testWidgets('non-receive tasks keep the existing generic layout',
      (tester) async {
    await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Movement'));

    expect(find.text('Movement'), findsOneWidget);
    expect(find.text('Task Info'), findsOneWidget);
    expect(find.text('From Inbound'), findsNothing);
    expect(
      isOutlinedButtonEnabled(tester, const Key('validate-location-button')),
      isTrue,
    );
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
          onCompleteTask: (taskId, {quantity, locationId}) async {
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

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '123456789012',
    );
    await scrollTo(tester, find.byKey(const Key('validate-product-button')));
    await tester.tap(find.byKey(const Key('validate-product-button')));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.text('To Shelf Location'), findsOneWidget);
    expect(find.text('SHELF-01-01'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('location-validate-field')),
      'SHELF-01-01',
    );
    await tester.tap(find.byKey(const Key('validate-location-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('refill-quantity-field')),
      '4',
    );
    await tester.pumpAndSettle();

    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedTaskId, 1);
    expect(completedQuantity, 4);
    expect(completedLocation, 'SHELF-01-01');
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

    await tester.enterText(
      find.byKey(const Key('product-validate-field')),
      '123456789012',
    );
    await scrollTo(tester, find.byKey(const Key('validate-product-button')));
    await tester.tap(find.byKey(const Key('validate-product-button')));
    await tester.pumpAndSettle();

    expect(find.text('To Shelf Location'), findsOneWidget);
    expect(find.text('SHELF-02-09'), findsOneWidget);
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
          onCompleteTask: (taskId, {quantity, locationId}) async {
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

    await tester.tap(find.byKey(const Key('return-validate-line-0-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('scan_barcode_field')), '123456789101');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('return-page-next-button')), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('return-page-next-button')),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('return-validate-line-1-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('scan_barcode_field')), '123456789102');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

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
      'adjustment task scans a location, previews decrease math, submits actual quantity, and finishes',
      (tester) async {
    String? scannedBarcode;
    String? submittedAdjustmentItemId;
    int? submittedActualQuantity;
    String? submittedNotes;
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
            required actualQuantity,
            String? notes,
          }) async {
            submittedAdjustmentItemId = adjustmentItemId;
            submittedActualQuantity = actualQuantity;
            submittedNotes = notes;
          },
          onCompleteTask: (taskId, {quantity, locationId}) async {
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

    expect(find.text('Current: 10'), findsNWidgets(2));
    expect(find.text('New: 10'), findsOneWidget);

    await scrollTo(tester, find.byKey(const Key('adjustment-mode-decrease')));
    await tester.tap(find.byKey(const Key('adjustment-mode-decrease')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('adjustment-delta-increment')));
    await tester.tap(find.byKey(const Key('adjustment-delta-increment')));
    await tester.tap(find.byKey(const Key('adjustment-delta-increment')));
    await tester.tap(find.byKey(const Key('adjustment-delta-increment')));
    await tester.pumpAndSettle();

    expect(find.text('Change: -3'), findsOneWidget);
    expect(find.text('New: 7'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('adjustment-note-field')),
      'damaged box',
    );
    await scrollTo(tester, find.byKey(const Key('adjustment-submit-button')));
    await tester.tap(find.byKey(const Key('adjustment-submit-button')));
    await tester.pumpAndSettle();

    expect(submittedAdjustmentItemId, 'adj-item-1');
    expect(submittedActualQuantity, 7);
    expect(submittedNotes, 'damaged box');
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
          onCompleteTask: (taskId, {quantity, locationId}) async {
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

    await tester.enterText(
      find.byKey(const Key('location-validate-field')),
      'SHELF-01-01',
    );
    await tester.tap(find.byKey(const Key('validate-location-button')));
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
    expect(find.text('10 counted'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();

    expect(completedQuantity, 10);
    expect(completedLocation, 'SHELF-01-01');
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
          onCompleteTask: (taskId, {quantity, locationId}) async {},
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

    await tester.enterText(
      find.byKey(const Key('location-validate-field')),
      'SHELF-09-03',
    );
    await tester.tap(find.byKey(const Key('validate-location-button')));
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
          onCompleteTask: (taskId, {quantity, locationId}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 counted'), findsOneWidget);
    expect(
      isElevatedButtonEnabled(tester, const Key('complete-task-button')),
      isFalse,
    );
  });

  testWidgets(
      'full-shelf cycle count scan opens detail without manual barcode entry',
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
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('location-validate-field')),
      'SHELF-09-03',
    );
    await tester.tap(find.byKey(const Key('validate-location-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cycle-count-hidden-scan-field')),
      'SKU-001',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Count Item'), findsOneWidget);
    expect(
      find.byKey(const Key('cycle-count-detail-barcode-field')),
      findsNothing,
    );
    expect(find.byKey(const Key('cycle-count-detail-quantity-field')),
        findsOneWidget);
  });
}
