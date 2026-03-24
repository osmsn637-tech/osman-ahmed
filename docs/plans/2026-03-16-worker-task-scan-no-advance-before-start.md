# Worker Task Scan No Advance Before Start Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent unopened worker tasks from auto-advancing to page two after a correct product scan.

**Architecture:** Keep the change inside `WorkerTaskDetailsPage`. Use the page's existing effective-task state to distinguish pending unopened tasks from started tasks, and drive the receive/refill page index from that state.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the pending-task scan rule with a failing widget test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that:
- pumps a pending unassigned receive task
- provides `onStartTask` and `onCompleteTask`
- enters the correct product barcode before start
- expects `right product`
- expects the location page to remain hidden

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because the current receive flow auto-advances immediately after validation.

**Step 3: Write minimal implementation**

Update product validation so receive and refill only move to page two when the effective task status is `TaskStatus.inProgress`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS

### Task 2: Preserve the started-task flow and verify regressions

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Keep existing started-task behavior**

- Leave mismatch handling unchanged
- Leave post-start receive/refill auto-advance unchanged
- Keep location validation and completion logic untouched

**Step 2: Verify**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS, including the existing receive flow completion test
