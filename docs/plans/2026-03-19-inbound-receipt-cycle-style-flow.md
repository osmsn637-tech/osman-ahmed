# Inbound Receipt Cycle-Style Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a dedicated inbound receipt two-page flow that routes PO scans away from the old receive page and mirrors cycle count interaction patterns with inbound-specific quantity gating.

**Architecture:** Add inbound receipt-specific entities and repository methods on top of the existing inbound feature, then introduce a new `InboundReceiptPage` with internal list/detail state. Keep the flow independent from `WorkerTaskDetailsPage` and update inbound home plus router wiring to navigate to `/inbound/receipt/:id`.

**Tech Stack:** Flutter, Provider, GoRouter, existing inbound repository/data source layer, Flutter widget tests.

---

### Task 1: Lock the new route handoff from inbound home

**Files:**
- Modify: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`
- Modify: `lib/features/inbound/presentation/pages/inbound_home_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`

**Step 1: Write the failing test**

Add a widget test that scans a PO from inbound home and expects navigation to `/inbound/receipt/:id` instead of `/receive`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart --plain-name "receive scan routes to the inbound receipt page"`
Expected: FAIL because the app still pushes `/receive`.

**Step 3: Write minimal implementation**

Update inbound home to read the scanned receipt id from `scanReceipt(...)` and push `/inbound/receipt/<id>`. Add the matching router entry.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart --plain-name "receive scan routes to the inbound receipt page"`
Expected: PASS.

**Step 5: Commit**

```bash
git add test/features/inbound/presentation/pages/inbound_home_page_test.dart lib/features/inbound/presentation/pages/inbound_home_page.dart lib/shared/providers/router_provider.dart
git commit -m "feat: route inbound receive scans to receipt page"
```

### Task 2: Add inbound receipt entities and repository surface

**Files:**
- Modify: `lib/core/constants/app_endpoints.dart`
- Modify: `lib/features/inbound/data/datasources/inbound_remote_data_source.dart`
- Modify: `lib/features/inbound/domain/repositories/inbound_repository.dart`
- Modify: `lib/features/inbound/data/repositories/inbound_repository_impl.dart`
- Modify: `test/support/fake_repositories.dart`
- Test: `test/features/inbound/data/repositories/inbound_repository_mock_test.dart`

**Step 1: Write the failing test**

Add tests that cover fake inbound receipt scan/load/item-scan/confirm behavior and endpoint constants.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/data/repositories/inbound_repository_mock_test.dart`
Expected: FAIL because the receipt-specific API surface does not exist yet.

**Step 3: Write minimal implementation**

Add receipt endpoints and minimal receipt entities/repository methods:

- scan PO to `receiptId`
- fetch/start a receipt
- scan a receipt item
- confirm a received quantity

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/data/repositories/inbound_repository_mock_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/core/constants/app_endpoints.dart lib/features/inbound/data/datasources/inbound_remote_data_source.dart lib/features/inbound/domain/repositories/inbound_repository.dart lib/features/inbound/data/repositories/inbound_repository_impl.dart test/support/fake_repositories.dart test/features/inbound/data/repositories/inbound_repository_mock_test.dart
git commit -m "feat: add inbound receipt repository surface"
```

### Task 3: Add the receipt page list state and tap/scan handoff

**Files:**
- Create: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Create: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 1: Write the failing test**

Add widget tests that assert the receipt page:

- shows `Receive`
- shows the scanned PO
- lists receipt items with barcode and receipt quantity
- opens detail with quantity disabled after a tap
- opens detail with quantity enabled after a list-page scan

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: FAIL because the page and controller do not exist.

**Step 3: Write minimal implementation**

Create a receipt controller/page pair with internal list/detail state and item-selection handoff that records whether detail was opened by scan or tap.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS for the initial list/detail behavior.

**Step 5: Commit**

```bash
git add lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart lib/features/inbound/presentation/pages/inbound_receipt_page.dart lib/shared/providers/app_providers.dart lib/shared/providers/router_provider.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart
git commit -m "feat: add inbound receipt list and detail flow"
```

### Task 4: Add quantity confirmation and list-page progress updates

**Files:**
- Modify: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Modify: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Modify: `test/support/fake_repositories.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that:

1. opens receipt detail by scan and confirms quantity without rescanning
2. opens receipt detail by tap and proves quantity stays locked until barcode scan
3. confirms quantity and returns to the list
4. verifies the list line shows the received quantity instead of `Pending`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart --plain-name "receipt detail confirms quantity and updates the list"`
Expected: FAIL because confirmation, gating, and list updates are missing.

**Step 3: Write minimal implementation**

Implement detail-page barcode validation for manual-open mode, quantity confirmation, and list updates keyed by receipt item id.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart lib/features/inbound/presentation/pages/inbound_receipt_page.dart test/support/fake_repositories.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart
git commit -m "feat: complete inbound receipt quantity flow"
```
