# Worker Home Opened Tasks First Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Render opened worker tasks at the top of the homepage task list.

**Architecture:** Keep controller and repository behavior unchanged. Sort the homepage `currentTasks` list at render time using the current session worker id so only the homepage ordering changes.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the ordering change with a failing widget test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write the failing test**

Add a widget test that:
- seeds one in-progress task assigned to the current worker
- seeds one pending unassigned task
- pumps the worker homepage
- verifies the opened task card appears before the pending task card

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --reporter expanded`
Expected: FAIL because the homepage currently preserves repository order.

**Step 3: Write minimal implementation**

Sort the homepage task list before building the sliver list.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --reporter expanded`
Expected: PASS

### Task 2: Verify related homepage regressions

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Apply homepage-only ordering**

- Sort opened tasks assigned to the current worker first
- Preserve the rest of the current list behavior

**Step 2: Verify**

Run:

```bash
flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --reporter expanded
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart --reporter expanded
```

Expected: PASS
