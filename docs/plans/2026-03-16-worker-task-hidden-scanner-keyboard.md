# Worker Task Hidden Scanner Keyboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent the soft keyboard from opening on task details while preserving scanner input capture.

**Architecture:** Update the hidden scanner `TextField`s in `WorkerTaskDetailsPage` to use `TextInputType.none` and cover both the cycle-count scan field and the shared hidden validation field with widget tests.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Lock expected keyboard behavior in tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

- Assert the cycle count hidden scan field uses `TextInputType.none`.
- Assert the shared hidden barcode validation field also uses `TextInputType.none`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the hidden fields still use `TextInputType.visiblePassword`.

### Task 2: Apply the minimal fix

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Update hidden field configuration**

- Change the hidden cycle count scan field to `TextInputType.none`.
- Change the shared hidden validation field helper to `TextInputType.none`.

**Step 2: Run the focused test again**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS

### Task 3: Sanity check

**Files:**
- Modify: touched files only

**Step 1: Format and verify**

Run: `dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
