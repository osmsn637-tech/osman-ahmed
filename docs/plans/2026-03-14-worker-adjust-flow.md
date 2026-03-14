# Worker Adjust Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a worker-home `Adjust` action that uses the existing scan dialog and shared item result page, then lets the worker submit a stock adjustment for one selected location with quantity stepper, reason options, optional note, and confirm.

**Architecture:** Keep the existing lookup route and result page, but introduce an explicit page mode so the result page can run in `lookup` or `adjust` mode. Use the existing lookup controller for item data and a new route-local adjustment controller for location selection and submission state, while extending the stock-adjustment request model to include an optional note field.

**Tech Stack:** Flutter, Provider, GoRouter, flutter_test

---

### Task 1: Add worker-home adjust entry and route mode handling

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_ar.arb`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Write the failing test**

Extend `worker_home_page_lookup_test.dart` with widget coverage that:

- expects both `Lookup` and `Adjust` buttons on the worker home page
- verifies `Adjust` appears below `Lookup`
- taps `Adjust`
- confirms the existing scan dialog opens on the same page

Suggested test names:

```dart
testWidgets('worker home shows adjust button below lookup', (tester) async {})
testWidgets('adjust button opens the shared scan popup', (tester) async {})
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart --plain-name "worker home shows adjust button below lookup"`
Expected: FAIL because the page only renders `Lookup`.

**Step 3: Write minimal implementation**

In `worker_home_page.dart`:

- extract the current lookup button builder into a helper so both buttons share style
- add a second full-width button directly under lookup
- reuse `showItemLookupScanDialog(context, showKeyboard: false)`
- push the same result route with `?mode=adjust`

Example navigation shape:

```dart
context.push(
  '/item-lookup/result/${Uri.encodeComponent(normalized)}?mode=adjust',
);
```

In `router_provider.dart`:

- parse `state.uri.queryParameters['mode']`
- default to `lookup` when query parameter is absent
- pass the mode into `ItemLookupResultPage`

Add minimal localization keys for:

- `workerAdjust`
- adjustment-mode page title if needed

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
Expected: PASS with both existing lookup coverage and new adjust coverage green.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_home_page.dart lib/shared/providers/router_provider.dart l10n/app_en.arb l10n/app_ar.arb test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart
git commit -m "feat: add worker adjust entry point"
```

### Task 2: Add adjustment request support with optional note

**Files:**
- Modify: `lib/features/move/domain/entities/stock_adjustment_params.dart`
- Modify: `lib/features/move/data/datasources/item_remote_data_source.dart`
- Modify: `lib/features/move/data/repositories/item_repository_mock.dart`
- Test: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing test**

Add a focused widget or controller-driven test in `item_lookup_flow_test.dart` that will eventually submit adjustment mode and expect note-aware payload handling. If the existing test file becomes too crowded, create `test/features/move/presentation/controllers/item_adjustment_controller_test.dart` instead and verify that a note can be passed through the request model without breaking success.

Minimal expected behavior:

```dart
expect(
  StockAdjustmentParams(
    itemId: 1001,
    locationId: 1,
    newQuantity: 2,
    reason: 'Damaged',
    workerId: 'worker-1',
    note: 'box torn',
  ).note,
  'box torn',
);
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: FAIL because `StockAdjustmentParams` does not include `note`.

**Step 3: Write minimal implementation**

Update `StockAdjustmentParams`:

```dart
class StockAdjustmentParams {
  const StockAdjustmentParams({
    required this.itemId,
    required this.locationId,
    required this.newQuantity,
    required this.reason,
    required this.workerId,
    this.note,
  });

  final String? note;
}
```

Update `item_remote_data_source.dart` to include note when present:

```dart
data: {
  'item_id': params.itemId,
  'location_id': params.locationId,
  'new_quantity': params.newQuantity,
  'reason': params.reason,
  'worker_id': params.workerId,
  if (params.note != null && params.note!.trim().isNotEmpty) 'note': params.note,
},
```

Keep `item_repository_mock.dart` returning success unchanged except for accepting the extended params.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: PASS with note-enabled params compiling cleanly.

**Step 5: Commit**

```bash
git add lib/features/move/domain/entities/stock_adjustment_params.dart lib/features/move/data/datasources/item_remote_data_source.dart lib/features/move/data/repositories/item_repository_mock.dart test/features/move/presentation/pages/item_lookup_flow_test.dart
git commit -m "feat: support stock adjustment notes"
```

### Task 3: Add route-local adjustment controller for selected-location submission

**Files:**
- Create: `lib/features/move/presentation/controllers/item_adjustment_controller.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Test: `test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 1: Write the failing test**

Create `item_adjustment_controller_test.dart` with tests that verify:

- quantity starts at `0`
- `decrement()` never goes below `0`
- selecting a location stores its `locationId`
- selecting a reason enables validation progress
- `canSubmit` stays false until location, quantity, and reason are present
- `submit()` sends the selected location id, item id, reason, and optional note

Suggested fake:

```dart
class _FakeAdjustStockUseCase {
  StockAdjustmentParams? lastParams;

  Future<Result<void>> call(StockAdjustmentParams params) async {
    lastParams = params;
    return const Success<void>(null);
  }
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`
Expected: FAIL because the controller does not exist.

**Step 3: Write minimal implementation**

Create `item_adjustment_controller.dart` with state like:

```dart
class ItemAdjustmentState {
  const ItemAdjustmentState({
    this.selectedLocationId,
    this.selectedLocationCode,
    this.quantity = 0,
    this.reason,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  bool get canSubmit =>
      selectedLocationId != null &&
      quantity > 0 &&
      reason != null &&
      !isSubmitting;
}
```

Controller API:

- `selectLocation(ItemLocationEntity location)`
- `increment()`
- `decrement()`
- `setReason(String value)`
- `setNote(String value)`
- `submitForItem(ItemLocationSummaryEntity summary)`

Submission should call `AdjustStockUseCase` with:

```dart
StockAdjustmentParams(
  itemId: summary.itemId,
  locationId: state.selectedLocationId!,
  newQuantity: state.quantity,
  reason: state.reason!,
  workerId: _session.state.user!.id,
  note: state.note.trim().isEmpty ? null : state.note.trim(),
)
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/move/presentation/controllers/item_adjustment_controller.dart lib/shared/providers/router_provider.dart test/features/move/presentation/controllers/item_adjustment_controller_test.dart
git commit -m "feat: add item adjustment controller"
```

### Task 4: Add shared result page adjust mode UI

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- Modify: `lib/shared/ui/location_row.dart`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_ar.arb`
- Test: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing test**

Extend `item_lookup_flow_test.dart` so it can open the shared result page in `adjust` mode and expect:

- item header still renders
- location rows are selectable
- adjustment panel appears only in `adjust` mode
- quantity starts at `0`
- `-` keeps quantity at `0`
- reason options include `Damaged` and `Return`
- confirm is disabled before selecting a location and increasing quantity

Suggested test names:

```dart
testWidgets('adjust mode shows selectable locations and adjustment panel', (tester) async {})
testWidgets('adjust mode quantity stepper never goes negative', (tester) async {})
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --plain-name "adjust mode shows selectable locations and adjustment panel"`
Expected: FAIL because the result page is read-only.

**Step 3: Write minimal implementation**

In `item_lookup_result_page.dart`:

- add a mode enum, for example:

```dart
enum ItemLookupPageMode { lookup, adjust }
```

- accept `mode` in the page constructor
- keep existing loading and error rendering shared
- when summary is available:
  - render current header and location sections
  - make each location row tappable in `adjust` mode
  - show selected styling based on `ItemAdjustmentController`
  - render one adjustment panel below sections only in `adjust` mode

Adjustment panel shape:

```dart
Column(
  children: [
    Row(
      children: [
        IconButton(key: const Key('adjust_quantity_decrement'), onPressed: controller.decrement),
        Text('${state.quantity}', key: const Key('adjust_quantity_value')),
        IconButton(key: const Key('adjust_quantity_increment'), onPressed: controller.increment),
      ],
    ),
    DropdownButtonFormField<String>(key: const Key('adjust_reason_field')),
    TextField(key: const Key('adjust_note_field')),
    ElevatedButton(
      key: const Key('adjust_confirm_button'),
      onPressed: state.canSubmit ? () => controller.submitForItem(summary) : null,
      child: Text(l10n.adjustConfirm),
    ),
  ],
)
```

Update `location_row.dart` only if needed to support a selected state without duplicating the row layout.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: PASS for lookup mode plus new adjust-mode UI tests.

**Step 5: Commit**

```bash
git add lib/features/move/presentation/pages/item_lookup_result_page.dart lib/shared/ui/location_row.dart l10n/app_en.arb l10n/app_ar.arb test/features/move/presentation/pages/item_lookup_flow_test.dart
git commit -m "feat: add adjust mode to item result page"
```

### Task 5: Wire submit feedback and protect existing lookup behavior

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Test: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing test**

Add tests that verify:

- successful confirm calls the adjustment controller and returns to `/home` or pops back
- failed confirm shows an inline error and keeps form state
- lookup mode still renders without adjustment controls

Suggested test names:

```dart
testWidgets('adjust mode confirm success returns after submit', (tester) async {})
testWidgets('lookup mode remains read only', (tester) async {})
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --plain-name "lookup mode remains read only"`
Expected: FAIL if the page was not split cleanly by mode, or because no submit success handling exists yet.

**Step 3: Write minimal implementation**

In `item_lookup_result_page.dart`:

- listen for adjustment success and pop the page when submit completes
- render inline error text from adjustment state above confirm
- disable confirm while submitting
- keep lookup mode unchanged by hiding selection chrome and the adjustment panel entirely

In `router_provider.dart`:

- create `ItemAdjustmentController` only once per result-page route
- pass the selected mode consistently

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: PASS with both lookup and adjust scenarios green.

**Step 5: Commit**

```bash
git add lib/features/move/presentation/pages/item_lookup_result_page.dart lib/shared/providers/router_provider.dart test/features/move/presentation/pages/item_lookup_flow_test.dart
git commit -m "feat: complete worker adjust flow"
```
