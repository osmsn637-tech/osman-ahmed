# Inbound Mobile Receipt Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the inbound home `Receive` shortcut to the old `/receive` page with a dedicated inbound mobile receipt flow that uses `/mobile/v1/inbound/*`, shows a receipt page with a visible `Start receiving` button, and opens an item detail page when the worker scans or taps a receipt item.

**Architecture:** Keep the new flow inside the inbound feature. Add inbound-mobile receipt entities plus a remote data source and repository methods for the new endpoints, then introduce a dedicated `InboundReceiptPage` with internal two-page state that mirrors the cycle count list/detail interaction model. Keep the existing inbound lookup action unchanged and stop routing inbound users into the old `ReceivePage`.

**Tech Stack:** Flutter, Provider, GoRouter, Dio `ApiClient`, existing shared scan dialog/widgets, Flutter widget tests.

---

### Task 1: Define the inbound mobile receipt API surface

**Files:**
- Modify: `lib/core/constants/app_endpoints.dart`
- Create: `lib/features/inbound/data/datasources/inbound_remote_data_source.dart`
- Modify: `lib/features/inbound/domain/entities/inbound_entities.dart`
- Modify: `lib/features/inbound/domain/repositories/inbound_repository.dart`
- Test: `test/support/fake_repositories.dart`

**Step 1: Write the failing type-level and fake-repository test**

Add a focused test that tries to call the new repository methods through `FakeInboundRepository`.

```dart
test('fake inbound repository exposes receipt scan and start flow', () async {
  final repo = FakeInboundRepository();
  final receipt = await repo.scanReceipt('RCV-1001');
  final started = await repo.startReceipt(
    receipt.id,
    receivedAt: DateTime.utc(2026, 3, 18, 1),
  );

  expect(started.status, InboundReceiptStatus.receiving);
});
```

**Step 2: Run the test to verify it fails**

Run: `flutter test test/support/fake_repositories.dart`
Expected: FAIL because the new receipt entities and repository methods do not exist yet.

**Step 3: Write the minimal API surface**

Add endpoint helpers:

```dart
static const inboundReceiptTasks = '/mobile/v1/inbound/receipts/my-tasks';
static const inboundReceiptScan = '/mobile/v1/inbound/receipts/scan';
static String inboundReceiptStart(String id) => '/mobile/v1/inbound/receipts/$id/start';
static String inboundReceiptScanItem(String id) => '/mobile/v1/inbound/receipts/$id/scan-item';
static String inboundReceiptProgress(String id) => '/mobile/v1/inbound/receipts/$id/progress';
static String inboundReceiptFinish(String id) => '/mobile/v1/inbound/receipts/$id/finish';
static String inboundReceiptItemConfirm(String id) => '/mobile/v1/inbound/receipt-items/$id/confirm';
static String inboundReceiptItemFlag(String id) => '/mobile/v1/inbound/receipt-items/$id/flag';
```

Add receipt-focused entities and params in `inbound_entities.dart` and new signatures in `InboundRepository`.

**Step 4: Add the remote data source shell**

Create `InboundRemoteDataSource` that mirrors the `TaskRemoteDataSource` pattern and returns parsed `Map<String, dynamic>` payloads for:

- `fetchMyTasks`
- `scanReceipt`
- `startReceipt`
- `scanReceiptItem`
- `confirmReceiptItem`
- `flagReceiptItem`
- `getReceiptProgress`
- `finishReceipt`

**Step 5: Update the fake repository**

Teach `FakeInboundRepository` to store receipt summaries, items, and progress for the new methods so widget tests can run without network calls.

**Step 6: Run the test to verify it passes**

Run: `flutter test test/support/fake_repositories.dart`
Expected: PASS.

**Step 7: Commit**

```bash
git add lib/core/constants/app_endpoints.dart lib/features/inbound/data/datasources/inbound_remote_data_source.dart lib/features/inbound/domain/entities/inbound_entities.dart lib/features/inbound/domain/repositories/inbound_repository.dart test/support/fake_repositories.dart
git commit -m "feat: add inbound mobile receipt api surface"
```

### Task 2: Wire the real inbound repository into providers

**Files:**
- Modify: `lib/features/inbound/data/repositories/inbound_repository_impl.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Test: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 1: Write the failing test for provider-backed scan navigation**

Extend the inbound home widget test so the fake repo returns a scanned receipt and the route target can be asserted.

```dart
testWidgets('receive action routes to inbound receipt page after scan', (tester) async {
  // tap Receive, complete scan dialog, assert router location is /inbound/receipt/<id>
});
```

**Step 2: Run the test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart --plain-name "receive action routes to inbound receipt page after scan"`
Expected: FAIL because the home page still pushes `/receive`.

**Step 3: Replace the repository implementation**

Refactor `InboundRepositoryImpl` to depend on `InboundRemoteDataSource` and map API payloads into the new receipt entities instead of maintaining the local `_store`.

Use the existing error propagation pattern:

```dart
final data = await _remote.scanReceipt(barcode: barcode);
return InboundReceiptSummary.fromMap(data);
```

**Step 4: Update provider wiring**

Add:

```dart
ProxyProvider<ApiClient, InboundRemoteDataSource>(
  update: (_, client, __) => InboundRemoteDataSource(client),
),
ProxyProvider<InboundRemoteDataSource, InboundRepository>(
  update: (_, remote, __) => InboundRepositoryImpl(remote),
),
```

Remove the no-dependency `InboundRepositoryImpl()` creation.

**Step 5: Run the test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart --plain-name "receive action routes to inbound receipt page after scan"`
Expected: PASS.

**Step 6: Commit**

```bash
git add lib/features/inbound/data/repositories/inbound_repository_impl.dart lib/shared/providers/app_providers.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart
git commit -m "feat: wire inbound receipt repository"
```

### Task 3: Replace inbound-home handoff to the old receive page

**Files:**
- Modify: `lib/features/inbound/presentation/pages/inbound_home_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Test: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 1: Write the failing widget test for the new route**

Add or tighten the test to assert the inbound `Receive` button lands on `/inbound/receipt/:id` and that lookup still lands on `/item-lookup/result/:barcode`.

```dart
expect(router.location, '/inbound/receipt/receipt-1001');
expect(find.text('Lookup'), findsOneWidget);
```

**Step 2: Run the test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: FAIL because the router does not expose the new route and the page still pushes `/receive`.

**Step 3: Write the minimal routing change**

Update `_openReceive`:

```dart
final receipt = await context.read<InboundRepository>().scanReceipt(normalized);
if (!context.mounted) return;
context.push('/inbound/receipt/${Uri.encodeComponent(receipt.id)}');
```

Add a new GoRouter entry for `/inbound/receipt/:id`.

Keep the old `/receive` route available for any non-inbound use that still depends on it, but stop sending inbound home there.

**Step 4: Run the test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/inbound/presentation/pages/inbound_home_page.dart lib/shared/providers/router_provider.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart
git commit -m "feat: route inbound receive scans to receipt flow"
```

### Task 4: Build the receipt page with explicit start behavior

**Files:**
- Create: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Create: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
- Test helper: `test/support/fake_repositories.dart`

**Step 1: Write the failing receipt-page tests**

Create tests for:

```dart
testWidgets('receipt page shows start button before receipt is active', ...);
testWidgets('starting a receipt enables item scanning', ...);
testWidgets('finish button stays disabled until receipt is started', ...);
```

**Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: FAIL because the controller/page do not exist yet.

**Step 3: Write the controller**

Add `InboundReceiptController` with state for:

- `receipt`
- `progress`
- `isStarting`
- `isFinishing`
- `isScanningItem`
- `selectedItem`
- `errorMessage`
- page mode: list vs detail

Key methods:

```dart
Future<void> load(String receiptId)
Future<void> startReceiving()
Future<void> scanItem(String barcode)
Future<void> refreshProgress()
void openItem(InboundReceiptItemCard item)
void closeItem()
```

**Step 4: Write the receipt page**

Mirror the cycle count layout:

- summary header
- progress summary
- list of receipt items with state chips
- shared hidden scan capture for item barcodes
- `Start receiving`
- `Finish receiving`

Block item scan until the receipt status is `receiving`.

**Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS.

**Step 6: Commit**

```bash
git add lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart lib/features/inbound/presentation/pages/inbound_receipt_page.dart lib/shared/providers/router_provider.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart test/support/fake_repositories.dart
git commit -m "feat: add inbound receipt page with start flow"
```

### Task 5: Add the item-detail page and confirm/flag loop

**Files:**
- Modify: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Modify: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
- Test helper: `test/support/fake_repositories.dart`

**Step 1: Write the failing tests for the second page**

Add tests for:

```dart
testWidgets('scanning an item opens the receipt item detail page', ...);
testWidgets('confirming an item returns to receipt page and updates progress', ...);
testWidgets('flagging an item returns to receipt page and updates progress', ...);
testWidgets('item not found stays on receipt page and shows an actionable error', ...);
```

**Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: FAIL because the detail page and submit actions are not implemented.

**Step 3: Implement the detail page**

Inside `InboundReceiptPage`, add the internal second-page state that matches cycle count:

- back button
- item name and barcode
- expected and received summary
- confirm fields:
  - `received_quantity`
  - `batch_number`
  - `expiry_date`
  - `manufacture_date`
  - `condition`
  - `notes`
- flag fields:
  - `condition`
  - `good_quantity`
  - `bad_quantity`
  - `notes`
  - `image_url`

**Step 4: Implement controller actions**

Add:

```dart
Future<void> confirmSelectedItem(ConfirmInboundReceiptItemParams params)
Future<void> flagSelectedItem(FlagInboundReceiptItemParams params)
```

Each action should:

- call the repository
- refresh receipt progress
- update the selected receipt item in local state
- return to list page on success

**Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS.

**Step 6: Commit**

```bash
git add lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart lib/features/inbound/presentation/pages/inbound_receipt_page.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart test/support/fake_repositories.dart
git commit -m "feat: add inbound receipt item detail actions"
```

### Task 6: Add finish-state and error-handling coverage

**Files:**
- Modify: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Modify: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
- Test helper: `test/support/fake_repositories.dart`

**Step 1: Write the failing tests for finish and error states**

Add tests for:

```dart
testWidgets('finish handles invalid status transition gracefully', ...);
testWidgets('forbidden start keeps the worker on the receipt page with guidance', ...);
testWidgets('unauthorized error surfaces re-login guidance', ...);
```

**Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: FAIL because controller error mapping and finish handling are incomplete.

**Step 3: Write the minimal behavior**

Map `AppException` types and backend error codes into user-facing messages without resetting the page:

```dart
String _messageForInboundError(AppException error) { ... }
```

Keep the worker on the current page for:

- `FORBIDDEN`
- `INVALID_ID`
- `INVALID_REQUEST`
- `ITEM_NOT_FOUND`
- `INVALID_STATUS_TRANSITION`

Only use session-expired guidance for `UNAUTHORIZED`.

**Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS.

**Step 5: Run the targeted inbound suite**

Run:

```bash
flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart
flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart
```

Expected: all PASS.

**Step 6: Commit**

```bash
git add lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart lib/features/inbound/presentation/pages/inbound_receipt_page.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart test/support/fake_repositories.dart
git commit -m "feat: complete inbound receipt error handling"
```
