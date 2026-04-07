# Worker Task Assignment Visibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Hide tasks assigned to other workers from the worker dashboard and show a clear status label on every visible task card.

**Architecture:** Filter the loaded task list inside `WorkerTasksController` using the signed-in worker id so the worker homepage only receives tasks that are unassigned or assigned to the current worker. Keep the homepage responsible for rendering a small status pill on each card, with the completed section still driven by controller state.

**Tech Stack:** Flutter, Provider, dashboard controller/page widgets, Flutter widget tests.

---

### Task 1: Add failing worker-home widget tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write a failing test for assignment visibility**
- Create a task assigned to `worker-2`.
- Verify that task does not appear when `worker-1` opens the worker home page.

**Step 2: Run the focused test**
- Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --plain-name "worker home hides tasks assigned to another worker everywhere"`
- Expected: FAIL because the page still shows that task.

**Step 3: Write a failing test for visible status labels**
- Verify a pending task shows `Pending`.
- Verify an in-progress task shows `In Progress`.
- Verify a completed task shows `Completed`.

**Step 4: Run the focused status test**
- Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --plain-name "worker home shows task status labels on visible cards"`
- Expected: FAIL because the card does not yet render those labels.

### Task 2: Filter tasks for the current worker in the controller

**Files:**
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`

**Step 1: Add a helper that checks assignment visibility**
- Keep unassigned tasks.
- Keep tasks assigned to the current worker.
- Drop tasks assigned to anyone else.

**Step 2: Apply the helper during load**
- Filter the fetched tasks before splitting them into current and completed.
- Keep the existing task-type API filter behavior intact.

**Step 3: Preserve reload behavior**
- Make sure refresh, claim, complete, and other reload paths still honor both the active task-type filter and the new visibility rule.

### Task 3: Render task status on worker-home cards

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`

**Step 1: Add a status label helper for task cards**
- Map `pending`, `inProgress`, and `completed` to user-facing text.
- Reuse existing app colors where possible.

**Step 2: Render a status pill in the task card header**
- Show the status pill on both current and completed cards.
- Keep the current type badge and action button behavior.

**Step 3: Avoid duplicate completed-only copy**
- Replace the old completed-only "Done" marker with the shared status label so every card uses one consistent pattern.

### Task 4: Verify the dashboard flow

**Files:**
- Modify as needed from tasks above

**Step 1: Run focused worker-home tests**
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 2: Run the related worker-home lookup regression suite**
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 3: Run analyzer on touched files**
- `dart analyze lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/features/dashboard/presentation/pages/worker_home_page.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
