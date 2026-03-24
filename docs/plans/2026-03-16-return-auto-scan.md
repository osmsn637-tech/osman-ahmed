# Return Auto Scan Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the per-row tap requirement from return barcode validation so scanning on the validation page automatically validates any matching unvalidated item.

**Architecture:** Add a scanner capture field dedicated to the return validation step, then route scanned barcodes through a matcher that finds the first unvalidated return row with the same barcode. Keep page-two return location and quantity behavior unchanged.

**Tech Stack:** Flutter, Dart, widget tests

---

### Task 1: Add the failing return auto-scan test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

- Update the return workflow test so it scans barcodes directly into a return scanner field without tapping `return-validate-line-*` buttons.
- Assert the matching rows validate and the next-page button enables automatically after both scans.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "return task uses a two-page multi-item workflow before completion"`
Expected: FAIL because the return page still requires row taps

### Task 2: Implement return auto scan

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal implementation**

- Add a scanner-friendly return barcode capture field to the validation page.
- Add a handler that matches a scanned barcode to the first unvalidated row with the same barcode and marks it validated.
- Keep row visuals, but remove the requirement to tap them before scanning.

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "return task uses a two-page multi-item workflow before completion"`
Expected: PASS

### Task 3: Format and verify

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Format**

Run: `dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 2: Run focused verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "return task uses a two-page multi-item workflow before completion"`
Expected: PASS

Run: `git diff --check`
Expected: no whitespace errors
