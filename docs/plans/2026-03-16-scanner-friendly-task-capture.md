# Scanner-Friendly Task Capture Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore reliable hardware scanner capture for cycle count and return flows while keeping the new auto-validation and manual keypad UX.

**Architecture:** Reconfigure the affected scanner capture `TextField`s so they remain focusable, editable scanner targets without relying on `TextInputType.none` or zero-sized layout. Cover the regression with focused widget tests that assert the scanner fields use scanner-friendly configuration in both the cycle-count page and the shared scan dialog.

**Tech Stack:** Flutter, Dart, widget tests

---

### Task 1: Add failing scanner-field regression tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

- Add a cycle-count widget test that inspects `cycle-count-hidden-scan-field` and asserts it does not use `TextInputType.none`.
- Update the scan-dialog widget test to assert `scan_barcode_field` does not use `TextInputType.none` and no longer has zero size.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL on scanner field config assertions

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: FAIL on dialog field config assertions

**Step 3: Commit**

```bash
git add test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart
git commit -m "test: cover scanner-friendly task capture fields"
```

### Task 2: Restore scanner-friendly capture fields

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`

**Step 1: Write minimal implementation**

- Change the cycle-count and hidden validation capture fields to use a scanner-friendly input configuration instead of `TextInputType.none`.
- Change the shared scan dialog capture field to use a scanner-friendly input configuration and non-zero layout while keeping it visually hidden.
- Preserve focus restore behavior and keyboard suppression.

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/move/presentation/pages/item_lookup_scan_dialog.dart
git commit -m "fix: restore scanner-friendly task capture"
```

### Task 3: Format and verify

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Format**

Run: `dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/move/presentation/pages/item_lookup_scan_dialog.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 2: Run focused verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: PASS

Run: `git diff --check`
Expected: no output

**Step 3: Commit**

```bash
git add docs/plans/2026-03-16-scanner-friendly-task-capture-design.md docs/plans/2026-03-16-scanner-friendly-task-capture.md lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/move/presentation/pages/item_lookup_scan_dialog.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart
git commit -m "fix: restore scanner input for cycle count and return"
```
