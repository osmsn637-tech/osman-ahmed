# Worker Home Task Filter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a one-row task-type filter to the worker homepage that filters only the current task list with the same labels and colors used by the task badges.

**Architecture:** Build the filter in `WorkerHomePage` from the currently loaded task list so the options always match the queue contents. Reuse the existing task visuals helpers for the label, icon, and color, and keep the completed section completely separate from the selected filter state.

**Tech Stack:** Flutter, Provider, existing dashboard task visuals helpers, Flutter widget tests.

---

### Task 1: Add failing widget tests for the filter behavior

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write the failing test for filter rendering**
- Verify the task filter row appears above current tasks with `ALL` and the current task-type pills.
- Verify the pills sit on one horizontal line.

**Step 2: Run the worker home task flow test file**
- Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
- Expected: FAIL because no filter row exists yet.

**Step 3: Write the failing test for filtering current tasks only**
- Verify selecting a type hides other current tasks.
- Verify completed tasks stay visible and unaffected.

**Step 4: Re-run the same test file**
- Expected: FAIL for the new filtering behavior.

### Task 2: Implement the worker home filter row

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`

**Step 1: Add local filter state**
- Store the selected current-task filter in the page state.

**Step 2: Build filter options from current tasks**
- Derive unique options from the currently ordered task queue.
- Treat receive and putaway labels consistently with the existing badge logic.

**Step 3: Add the one-row filter UI**
- Place it under the current-task section header.
- Add an `ALL` pill plus one pill per current task filter option.
- Reuse task label/color/icon helpers.

**Step 4: Filter only the current task list**
- Apply the selected filter to the current-task cards only.
- Leave completed tasks and counts untouched.

### Task 3: Verify the implementation

**Files:**
- Modify as needed from tasks above

**Step 1: Run focused widget tests**
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 2: Run the related worker home regression test file**
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 3: Run analyzer on touched files**
- `flutter analyze lib/features/dashboard/presentation/pages/worker_home_page.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
