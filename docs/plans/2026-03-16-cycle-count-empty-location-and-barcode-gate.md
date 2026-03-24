# Cycle Count Empty Location And Barcode Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Require explicit cycle count location input and block quantity entry until barcode validation succeeds.

**Architecture:** Keep the change local to `WorkerTaskDetailsPage`. Special-case cycle count when initializing the location controller, and derive the detail quantity field enabled state from the selected cycle count item's barcode validation state.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the cycle count location input behavior with a failing test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that:
- pumps a cycle count task with `toLocation`
- verifies the reference shelf text is visible
- verifies the hidden location field starts empty

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because cycle count currently inherits the prefilled location controller value.

**Step 3: Write minimal implementation**

Initialize cycle count location capture with an empty controller value while keeping the displayed reference row unchanged.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS

### Task 2: Lock quantity until barcode validation succeeds

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that:
- opens a cycle count item detail manually
- verifies the quantity field is disabled before barcode validation
- validates the correct barcode
- verifies the quantity field becomes enabled

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because the quantity field is currently editable immediately.

**Step 3: Write minimal implementation**

Disable the cycle count detail quantity `TextField` until the selected item's barcode has been validated.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS
