# Cycle Count Frontend-Only Item Scan Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Revert cycle count item barcode scans to frontend-only matching while keeping cycle count location validation unchanged.

**Architecture:** Keep backend validation for location scans only. The cycle count list-page item scan remains a local UI concern that matches the scanned barcode against the task’s existing cycle count items and opens the selected detail page when found.

**Tech Stack:** Flutter, Dart, widget tests

---

### Task 1: Write The Failing Widget Regression

**Files:**
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

- Update the full-shelf cycle count scan test so:
  - location validation still records one callback call
  - item barcode scan does not add a second callback call

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "full-shelf cycle count scan opens detail without manual barcode entry"`

Expected: FAIL because the current item scan path still calls the validation callback.

### Task 2: Remove Backend Validation From Item Scan

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal implementation**

- Remove the backend validation callback call from `_submitCycleCountScan(...)`.
- Keep the local barcode match and existing mismatch message.

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "full-shelf cycle count scan opens detail without manual barcode entry"`

Expected: PASS

### Task 3: Format And Verify

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Format**

Run: `dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 2: Focused verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 3: Report blockers honestly**

- If format or test commands still hang in this shell, report the exact commands attempted and the timeout behavior.
