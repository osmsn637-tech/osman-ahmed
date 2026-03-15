# Cycle Count Multi-Item Scan Handoff Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make multi-item cycle count tasks treat a successful item scan as a completed handoff into the count detail page instead of presenting manual barcode entry as if scanning failed.

**Architecture:** Keep the existing two-page cycle count flow and adjust only the detail-page handoff state. The list-page scan continues to select the item, but the detail page now distinguishes scan-opened vs manually-opened states so the manual barcode field is only shown when it is actually needed.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Add the regression test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test for a full-shelf cycle count task that:

- validates the location
- scans a known item barcode from the list page
- expects the count detail page to open
- expects the manual barcode field to stay hidden for the scan-opened path

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "full-shelf cycle count scan opens detail without manual barcode entry"`
Expected: FAIL because the detail page currently always renders the manual barcode field.

### Task 2: Implement scan/manual detail-page separation

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal implementation**

Keep `_cycleCountDetailOpenedManually` as the source of truth and render the manual barcode field only when the worker opened the item manually from the list.

**Step 2: Run the targeted test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "full-shelf cycle count scan opens detail without manual barcode entry"`
Expected: PASS

### Task 3: Verify affected cycle count flows

**Files:**
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Run broader verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS
