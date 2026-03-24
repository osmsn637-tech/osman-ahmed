# Cycle Count Scan And Submit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Route cycle count scans through the worker scan endpoint and route cycle count completion through the worker submit endpoint.

**Architecture:** Keep cycle count endpoint selection centralized in the dashboard repository, and reuse the existing worker-page validation callback for cycle count barcode scans so the UI does not gain a second backend contract. The widget remains responsible for local item selection while the repository remains responsible for endpoint routing.

**Tech Stack:** Flutter, Dart, Provider, widget tests

---

### Task 1: Lock Repository Completion Routing

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Test: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

- Add a repository test that loads a `cycle_count` task, calls `completeTask(...)`, and expects:
  - `submittedTaskId` is the cycle count remote id
  - `submittedTaskType` is `cycle_count`
  - `completedTaskId` stays `null`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "completeTask submits cycle count tasks without calling complete endpoint"`

Expected: FAIL because the repository still calls `completeTask(...)` for cycle count.

**Step 3: Write minimal implementation**

- Special-case `cycle_count` in `TaskRepositoryImpl.completeTask(...)` so it goes straight to `submitTask(...)`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "completeTask submits cycle count tasks without calling complete endpoint"`

Expected: PASS

### Task 2: Send Cycle Count Item Scans Through Backend

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

- Add a widget test that opens a cycle count task, validates location, scans an item barcode on the list page, and expects the injected validation callback to be called before the item detail page opens.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count list scan validates through callback before opening item"`

Expected: FAIL because the current list scan path is local-only.

**Step 3: Write minimal implementation**

- Reuse `onValidateLocation` for cycle count item scan submission.
- After a valid response, keep the local item lookup and open the matched item.
- Preserve the existing mismatch error behavior when no item matches or the backend rejects the scan.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count list scan validates through callback before opening item"`

Expected: PASS

### Task 3: Format And Verify

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Format**

Run: `dart format lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 2: Focused verification**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 3: Report blockers honestly**

- If Flutter commands still hang in this shell, report the exact commands attempted and that verification remains environment-blocked.
