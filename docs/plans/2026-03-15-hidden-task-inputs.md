# Hidden Task Inputs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace visible task barcode and location inputs with hidden scan capture plus manual entry actions, and ensure all task count submissions send final quantity values to the API.

**Architecture:** Keep the change centered in `WorkerTaskDetailsPage` by introducing shared hidden scan targets and task-step aware manual entry dialogs instead of maintaining duplicated visible `TextField` logic in each task layout. Normalize quantity payload handling through the existing dashboard controller, use case, repository, and remote datasource stack so the UI and data layers agree on `quantity` semantics.

**Tech Stack:** Flutter, Provider, widget tests, repository tests, Dart/Flutter test runner

---

### Task 1: Lock The New Task-Input Behavior With Failing Widget Tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Reference: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing test**

Add focused widget coverage for the new interaction model:

```dart
testWidgets('move task hides visible validation fields and shows manual type actions',
    (tester) async {
  await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('product-validate-field')), findsNothing);
  expect(find.byKey(const Key('location-validate-field')), findsNothing);
  expect(find.byKey(const Key('hidden-barcode-scan-field')), findsOneWidget);
  expect(find.byKey(const Key('hidden-location-scan-field')), findsOneWidget);
  expect(find.byKey(const Key('manual-barcode-entry-button')), findsOneWidget);
  expect(find.byKey(const Key('manual-location-entry-button')), findsOneWidget);
});

testWidgets('barcode manual type rejects non-digit entry', (tester) async {
  await tester.pumpWidget(wrap(WorkerTaskDetailsPage(task: buildTask())));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('manual-barcode-entry-button')));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('manual-barcode-dialog-field')), 'SKU-001');
  await tester.tap(find.byKey(const Key('manual-barcode-dialog-submit')));
  await tester.pumpAndSettle();

  expect(find.text('Enter digits only'), findsOneWidget);
});
```

Also update the existing tests that currently call `enterText` on `product-validate-field` and `location-validate-field` so they instead interact through the hidden scan fields or the new manual-entry buttons.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the page still renders visible validation fields and does not expose the hidden shared scan keys or manual-entry buttons.

**Step 3: Write minimal implementation**

No production code yet. The point of this task is to prove the test is checking missing behavior.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL with missing widget keys such as `hidden-barcode-scan-field` or `manual-barcode-entry-button`, not with a broken test harness.

**Step 5: Commit**

```bash
git add test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "test: cover hidden task scan inputs"
```

### Task 2: Implement Shared Hidden Scan Targets And Manual Entry UI

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Extend the widget coverage to assert focus routing and task progression through the hidden scanner fields:

```dart
testWidgets('receive task advances from hidden barcode scan to hidden location scan',
    (tester) async {
  await tester.pumpWidget(
    wrap(
      WorkerTaskDetailsPage(
        task: buildTask(type: TaskType.receive, fromLocation: null, toLocation: 'BULK-01-02'),
        onCompleteTask: (taskId, {quantity, locationId}) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('hidden-barcode-scan-field')),
    '123456789012',
  );
  await tester.pumpAndSettle();

  expect(find.text('Product validated'), findsOneWidget);
  expect(find.byKey(const Key('manual-location-entry-button')), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because hidden scan routing and manual dialog flows are not wired into the task page yet.

**Step 3: Write minimal implementation**

Refactor `WorkerTaskDetailsPage` around shared scan targets:

```dart
enum _ActiveTaskInputTarget { none, barcode, location }

late final TextEditingController _hiddenBarcodeScanController;
late final TextEditingController _hiddenLocationScanController;
late final FocusNode _hiddenBarcodeScanFocusNode;
late final FocusNode _hiddenLocationScanFocusNode;

_ActiveTaskInputTarget get _activeTaskInputTarget { ... }

Widget _buildHiddenScanFields() {
  return Column(
    children: [
      _HiddenScanField(
        key: const Key('hidden-barcode-scan-field'),
        controller: _hiddenBarcodeScanController,
        focusNode: _hiddenBarcodeScanFocusNode,
        onChanged: _handleHiddenBarcodeScanChanged,
      ),
      _HiddenScanField(
        key: const Key('hidden-location-scan-field'),
        controller: _hiddenLocationScanController,
        focusNode: _hiddenLocationScanFocusNode,
        onChanged: _handleHiddenLocationScanChanged,
      ),
    ],
  );
}
```

Replace every visible barcode/location validation `TextField` in the page with:

- the corresponding validation status message
- a `Manual Type` button
- existing validate button only if the flow still requires explicit confirmation after scan parsing

Manual entry should use dialogs:

```dart
Future<void> _openManualBarcodeEntry() async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => const _ManualBarcodeDialog(),
  );
  if (result != null) {
    _handleBarcodeValue(result);
  }
}

Future<void> _openManualLocationEntry() async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => const _ManualLocationDialog(),
  );
  if (result != null) {
    _handleLocationValue(result);
  }
}
```

Keep barcode input numeric-only:

```dart
String _normalizeNumericBarcode(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits;
}
```

Restore focus after every accepted or rejected attempt:

```dart
void _restoreActiveScannerFocus() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    switch (_activeTaskInputTarget) {
      case _ActiveTaskInputTarget.barcode:
        _hiddenBarcodeScanFocusNode.requestFocus();
      case _ActiveTaskInputTarget.location:
        _hiddenLocationScanFocusNode.requestFocus();
      case _ActiveTaskInputTarget.none:
        break;
    }
  });
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS with hidden field/manual-entry coverage green and no remaining references to visible validation fields in worker task flows.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: hide worker task scan inputs"
```

### Task 3: Lock Quantity Payload Semantics With Data-Layer Tests

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Reference: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Reference: `lib/features/dashboard/data/datasources/task_remote_data_source.dart`
- Reference: `lib/features/dashboard/domain/repositories/task_repository.dart`

**Step 1: Write the failing test**

Rename the adjustment-count expectation to `quantity` and add a regression for task completion quantities:

```dart
test('submitAdjustmentCount sends quantity and notes', () async {
  await repository.submitAdjustmentCount(
    taskId: task.id,
    adjustmentItemId: 'adj-item-1',
    quantity: 7,
    notes: 'checked',
  );

  expect(remote.submittedAdjustmentItemId, 'adj-item-1');
  expect(remote.submittedQuantity, 7);
  expect(remote.submittedAdjustmentNotes, 'checked');
});

test('completeTask falls back with final quantity for cycle count', () async {
  await repository.completeTask(task.id, quantity: 12, locationId: 'SHELF-01');

  expect(remote.submittedQuantity, 12);
});
```

Update the fake datasource inside the same test file so it stores `submittedQuantity` for adjustment count instead of `submittedActualQuantity`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`

Expected: FAIL because the repository and datasource interfaces still use `actualQuantity`.

**Step 3: Write minimal implementation**

Thread `quantity` through the dashboard count stack:

```dart
abstract class TaskRepository {
  Future<void> submitAdjustmentCount({
    required int taskId,
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  });
}

class SubmitAdjustmentCountUseCase {
  Future<void> execute({
    required int taskId,
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  }) {
    return _repo.submitAdjustmentCount(
      taskId: taskId,
      adjustmentItemId: adjustmentItemId,
      quantity: quantity,
      notes: notes,
    );
  }
}
```

In the remote datasource, send the quantity field the user asked for:

```dart
Future<void> submitAdjustmentCount({
  required String adjustmentItemId,
  required int quantity,
  String? notes,
}) async {
  await _client.post<void>(
    AppEndpoints.adjustmentItemCount(adjustmentItemId),
    data: {
      'quantity': quantity,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    },
  );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`

Expected: PASS with repository payload assertions using `quantity`.

**Step 5: Commit**

```bash
git add test/features/dashboard/data/repositories/task_repository_impl_test.dart lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/data/datasources/task_remote_data_source.dart
git commit -m "refactor: send quantity for task item counts"
```

### Task 4: Wire The Renamed Quantity Contract Through The UI And Verify End To End

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`
- Modify: `lib/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write the failing test**

Update the adjustment widget tests so they assert the UI passes `quantity` instead of `actualQuantity`:

```dart
testWidgets('adjustment submission passes final quantity', (tester) async {
  int? submittedQuantity;

  await tester.pumpWidget(
    wrap(
      WorkerTaskDetailsPage(
        task: buildTask(type: TaskType.adjustment),
        onSubmitAdjustmentCount: ({
          required adjustmentItemId,
          required quantity,
          String? notes,
        }) async {
          submittedQuantity = quantity;
        },
      ),
    ),
  );

  // drive adjustment flow...

  expect(submittedQuantity, 7);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the page and controller callback signatures still expect `actualQuantity`.

**Step 3: Write minimal implementation**

Update all callback signatures and call sites:

```dart
final Future<void> Function({
  required String adjustmentItemId,
  required int quantity,
  String? notes,
})? onSubmitAdjustmentCount;

await submitter(
  adjustmentItemId: selected.adjustmentItemId,
  quantity: _adjustmentPreviewQuantity,
  notes: trimmedNotes,
);
```

Propagate the same signature through `WorkerHomePage` and `WorkerTasksController`.

**Step 4: Run test to verify it passes**

Run:
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

Expected: PASS with the renamed quantity contract wired from page to controller.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart
git commit -m "refactor: use quantity across adjustment flows"
```

### Task 5: Final Verification And Cleanup

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Run targeted verification**

Run:

```bash
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart
flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart
flutter analyze lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/dashboard/data/repositories/task_repository_impl.dart
```

Expected: all targeted tests pass and analyzer reports no new issues in the touched dashboard files.

**Step 2: Format touched files**

Run:

```bash
dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/data/datasources/task_remote_data_source.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart
```

**Step 3: Re-run verification**

Run the same commands from Step 1.

Expected: still green after formatting.

**Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/submit_adjustment_count_usecase.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/data/datasources/task_remote_data_source.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart docs/plans/2026-03-15-hidden-task-inputs-design.md docs/plans/2026-03-15-hidden-task-inputs.md
git commit -m "feat: hide task scan inputs and normalize quantities"
```
