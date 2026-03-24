# Inbound Receipt Start And Match Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the inbound home `Receive` flow open a dedicated inbound receipt page that requires `Start receiving` before item handling and turns receipt rows green only when the entered quantity matches the receipt quantity.

**Architecture:** Reuse the existing inbound receipt route, controller, and page instead of changing the generic receive page. Extend the inbound receipt domain state with an explicit started/receiving status, add a repository start action, and update the receipt list/detail UI to mirror the cycle-count flow more closely while keeping the scope limited to inbound-home receive.

**Tech Stack:** Flutter, Provider, GoRouter, existing inbound repository/data source, Flutter widget tests, fake repositories.

---

### Task 1: Add receipt start support to the inbound domain and fake repository

**Files:**
- Modify: `lib/features/inbound/domain/repositories/inbound_repository.dart`
- Modify: `lib/features/inbound/data/repositories/inbound_repository_impl.dart`
- Modify: `lib/features/inbound/data/datasources/inbound_remote_data_source.dart`
- Modify: `test/support/fake_repositories.dart`
- Test: `test/features/inbound/data/repositories/inbound_repository_mock_test.dart`

**Step 1: Write the failing repository test**

Add a test that starts a scanned receipt and expects the status to change from pending to receiving.

**Step 2: Run the test to verify it fails**

Run: `flutter test test/features/inbound/data/repositories/inbound_repository_mock_test.dart --plain-name "starting a receipt switches it to receiving"`
Expected: FAIL because the repository has no start action.

**Step 3: Write the minimal implementation**

Add `startReceipt` to the repository contract, implementation, remote data source, and fake repository.

**Step 4: Run the test to verify it passes**

Run the same command and expect PASS.

### Task 2: Add failing receipt page tests for the new flow

**Files:**
- Modify: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 1: Write the failing tests**

Add tests for:
- showing a visible `Start receiving` button before receipt items are active
- keeping item scan/detail disabled before start
- turning an item row green when confirmed quantity equals receipt quantity
- keeping a non-matching confirmed row non-green

**Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: FAIL because the current page has no start gate or row-match styling.

### Task 3: Extend the inbound receipt controller for start state and match state

**Files:**
- Modify: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`

**Step 1: Write the minimal controller changes**

Add:
- `isStarting`
- `canReceiveItems`
- `startReceiving()`
- helper(s) for row state such as `isItemMatched(item)` and `isItemHandled(item)`

Ensure scan/open/confirm actions are blocked until the receipt is started.

**Step 2: Run the receipt tests**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: still failing on UI until the page is updated.

### Task 4: Update the inbound receipt page to mirror the cycle-count list/detail shape

**Files:**
- Modify: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`

**Step 1: Write the minimal UI changes**

Update the list page to show:
- receipt header
- `Start receiving` button
- disabled item list before start
- item rows with receipt quantity always visible
- green row styling only when `receivedQuantity == receiptQuantity`

Update the detail page to keep quantity entry behind the start gate.

**Step 2: Run the receipt tests**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
Expected: PASS.

### Task 5: Verify inbound-home receive handoff still works

**Files:**
- Modify: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 1: Add or tighten the route assertion**

Assert the inbound home `Receive` action still opens the inbound receipt route with the scanned receipt id.

**Step 2: Run the failing/passing test**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: PASS after alignment.

### Task 6: Final targeted verification

**Files:**
- Modify if needed based on failures

**Step 1: Run targeted verification**

Run:
- `flutter test test/features/inbound/data/repositories/inbound_repository_mock_test.dart`
- `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`
- `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 2: Report actual results**

State exactly which commands passed and which still have residual issues.
