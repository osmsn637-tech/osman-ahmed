import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
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
    String? itemBarcode = '123456789012',
    String? itemImageUrl = 'https://example.com/item.png',
    String? fromLocation = 'Z01-C01-L01-P01',
    String? toLocation = 'Z01-BLK-C01-L01-P01',
    TaskStatus status = TaskStatus.inProgress,
    String? assignedTo = '2bcf9d5d-1234-4f1d-8f6d-000000000007',
  }) {
    return TaskEntity(
      id: 1,
      type: type,
      itemId: 1001,
      itemName: 'Demo Item',
      fromLocation: fromLocation,
      toLocation: toLocation,
      quantity: 12,
      assignedTo: assignedTo,
      status: status,
      createdBy: 'system',
      zone: 'Z01',
      itemBarcode: itemBarcode,
      itemImageUrl: itemImageUrl,
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

  testWidgets('shows a visible error when starting a task fails', (tester) async {
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

    expect(find.text('Failed to start task. Please try again.'), findsOneWidget);
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
}
