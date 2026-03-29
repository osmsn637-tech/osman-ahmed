# Scan Guidance and Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add clear next-step guidance and stronger scan feedback to worker task execution and inbound receipt flows.

**Architecture:** Keep the change local to the two scanner-heavy presentation pages and drive the new UI from state that already exists. Use widget tests to lock the visible guidance transitions first, then add the smallest possible UI/controller changes to make them pass.

**Tech Stack:** Flutter, Provider, Dart, flutter_test

---

### Task 1: Lock worker-task guidance behavior with widget tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add focused widget tests that assert:

- receive flow starts with a visible `Next step` panel telling the user to scan the product
- after a successful product scan, the panel changes to instruct the user to scan the location
- failed product scans still show the stronger validation feedback card

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because the new guidance panel and updated copy do not exist yet.

**Step 3: Write minimal implementation**

Add a small worker-task guidance helper/widget inside `worker_task_details_page.dart` and render it from the existing receive/refill/return/cycle-count state.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS

### Task 2: Lock inbound guidance behavior with widget tests

**Files:**
- Modify: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 1: Write the failing tests**

Add focused widget tests that assert:

- the receipt list page shows `Next step` guidance before receiving starts
- after starting the receipt, the list guidance changes to scanning items
- tapping into detail shows guidance to scan the line barcode first
- scanning into detail shows guidance to enter and confirm quantity
- barcode mismatch still shows the stronger negative feedback treatment

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart --reporter expanded`
Expected: FAIL because the new guidance panel and updated feedback treatment do not exist yet.

**Step 3: Write minimal implementation**

Expose the smallest extra receipt state needed for UI-only success feedback and render the new guidance/feedback components in `inbound_receipt_page.dart`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart --reporter expanded`
Expected: PASS

### Task 3: Implement stronger feedback treatment and inbound feedback parity

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`
- Modify: `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Test: `test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 1: Add the minimal production changes**

- add a reusable `Next step` card treatment in each page
- make task-page validation cards slightly stronger without changing the workflow logic
- add inbound success/failure scan feedback using Flutter system feedback APIs
- keep existing navigation, repository, and submission behavior unchanged

**Step 2: Run focused tests**

Run:

```bash
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded
flutter test test/features/inbound/presentation/pages/inbound_receipt_page_test.dart --reporter expanded
```

Expected: PASS

### Task 4: Run full verification

**Files:**
- Modify: `docs/app-documentation.md`

**Step 1: Update docs if the visible behavior changed enough to document**

Add a short note that task execution and inbound receipt flows now provide explicit next-step guidance and stronger scan-result feedback.

**Step 2: Run verification**

Run:

```bash
flutter test --reporter expanded
dart analyze
```

Expected: tests pass and analysis stays clean or only shows pre-existing non-blocking info-level findings.
