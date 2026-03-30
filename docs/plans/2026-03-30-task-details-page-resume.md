# Task Details Page Resume Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reopen multi-step worker tasks on their last in-app page instead of always resetting to page 1.

**Architecture:** Keep the resume state local to the app session inside `WorkerTasksController`, keyed by task id. `WorkerHomePage` passes the saved resume state into `WorkerTaskDetailsPage`, and the details page reports page changes back to the controller whenever the active step changes or resets.

**Tech Stack:** Flutter, Provider, Dart widget tests

---

### Task 1: Capture The Expected Behavior In Tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write the failing widget tests**

Add tests that cover:
- `WorkerTaskDetailsPage` starting on page 2 when a saved resume state is passed for receive, refill, return, and cycle count.
- `WorkerHomePage` reopening an in-progress multi-step task on page 2 after the user leaves the details page and opens it again.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL because the details page cannot accept or restore resume state yet.

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Expected: FAIL because reopening still rebuilds the task details page from page 1.

### Task 2: Add Lightweight Resume-State Plumbing

**Files:**
- Create: `lib/features/dashboard/presentation/models/task_detail_resume_state.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`

**Step 1: Add a small immutable resume-state model**

Include:
- active page index
- optional cycle count selected item key
- optional cycle count detail flags needed to reopen page 2 safely

**Step 2: Add controller storage helpers**

Add methods to:
- read a task's resume state
- save/update a task's resume state
- clear resume state when it resets to page 1
- prune stale resume state after task lists reload

**Step 3: Run controller-adjacent tests**

Run: `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
Expected: PASS

### Task 3: Wire Home And Details Pages Together

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Pass saved resume state into the details page**

When opening task details, read the saved state from `WorkerTasksController` and pass it through the route builder.

**Step 2: Restore the initial page in the details page**

For receive, refill, return, and cycle count:
- restore page 2 when a valid resume state exists
- restore the cycle count detail item when needed
- keep page resets legal if the task state no longer supports page 2

**Step 3: Save page changes back to the controller**

Report resume-state updates whenever the details page:
- advances from page 1 to page 2
- resets back to page 1
- returns from cycle count detail back to the list
- completes the task

**Step 4: Run focused tests**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Expected: PASS

### Task 4: Verify The Full Change

**Files:**
- Verify touched files only

**Step 1: Run final verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Expected: PASS

Run: `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
Expected: PASS

**Step 2: Commit**

```bash
git add docs/plans/2026-03-30-task-details-page-resume.md \
  lib/features/dashboard/presentation/models/task_detail_resume_state.dart \
  lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart \
  lib/features/dashboard/presentation/pages/worker_home_page.dart \
  lib/features/dashboard/presentation/pages/worker_task_details_page.dart \
  test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart \
  test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart \
  test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: resume multi-step worker task details"
```
