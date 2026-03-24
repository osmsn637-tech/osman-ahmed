# Worker Task Scan Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve task-page scan reliability with autofocus, success/failure feedback sounds, and delayed clearing of failed scans.

**Architecture:** Keep the behavior inside `WorkerTaskDetailsPage` by extending the existing hidden validation field builder and the current product/location scan handlers. Reuse `SystemSound` and `HapticFeedback` so the task page matches the rest of the app's scan feedback behavior without adding dependencies.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the failed-scan clear behavior with tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add focused widget tests that:
- verify the hidden product validation field has autofocus enabled
- enter an invalid product barcode
- verify the mismatch message appears
- advance fake time by 2 seconds
- verify the hidden field value is cleared

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because the current hidden field is not autofocus-enabled and failed product scans do not clear themselves.

**Step 3: Write minimal implementation**

Extend the hidden-field builder to support autofocus and add a delayed clear path for failed product/location scans.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS

### Task 2: Add scan feedback and preserve current success flows

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Reuse built-in scan feedback**

- play success feedback on valid completed scans
- play failure feedback on invalid completed scans
- keep current receive/refill page transitions unchanged for valid scans

**Step 2: Verify**

Run:

```bash
flutter analyze lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded
```

Expected: PASS
