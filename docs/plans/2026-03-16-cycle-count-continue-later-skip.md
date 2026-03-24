# Cycle Count Continue Later Skip Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire cycle count `Continue Later` to the skip endpoint while preserving counted products when the pending task is reopened.

**Architecture:** Add an explicit skip path to the dashboard repository and worker controller, and keep cycle count progress in local workflow data as a merge overlay on top of fresh remote tasks. Remote task status stays authoritative, while local `cycleCountProgress` remains authoritative for reopen state.

**Tech Stack:** Flutter, Dart, Provider, widget tests

---

### Task 1: Add Repository Red Tests

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing tests**

- Add a repository test proving `skipTask(...)` on a cycle count task calls the fake remote `skipTask(...)` with `task_type: cycle_count`.
- Add a repository test proving saved `cycleCountProgress` survives a fresh remote fetch while the remote pending status still wins.

**Step 2: Run tests to verify they fail**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "skipTask pauses cycle count tasks through skip endpoint"`
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "remote cycle count refresh keeps saved progress but restores pending status"`

Expected: FAIL because the repository has no skip method and currently prefers the full cached task.

### Task 2: Add Worker Flow Red Test

**Files:**
- Modify: `test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
- Modify: `test/support/fake_repositories.dart`

**Step 1: Write the failing test**

- Add a controller test proving cycle count continue-later saves progress, calls skip, and reloads with the task pending.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

Expected: FAIL because there is no continue-later skip path in the controller yet.

### Task 3: Implement Skip And Merge

**Files:**
- Modify: `lib/features/dashboard/domain/repositories/task_repository.dart`
- Create: `lib/features/dashboard/domain/usecases/skip_task_usecase.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/support/fake_repositories.dart`

**Step 1: Write minimal implementation**

- Add generic `skipTask(...)` support to the task repository.
- Implement remote skip routing in `TaskRepositoryImpl`.
- Remove the claimed-task override when a task is skipped.
- Merge only `cycleCountProgress` from cached local workflow data onto fresh remote cycle count tasks.
- Add a worker controller method for cycle count continue later that saves progress, skips the task, and reloads.
- Wire `WorkerTaskDetailsPage` continue later to the new callback.

**Step 2: Run tests to verify they pass**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

Expected: PASS

### Task 4: Format And Verify

**Files:**
- Modify all files touched above

**Step 1: Format**

Run: `dart format lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/skip_task_usecase.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/shared/providers/app_providers.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart test/support/fake_repositories.dart`

**Step 2: Focused verification**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

**Step 3: Report blockers honestly**

- If Dart or Flutter commands still hang in this shell, report the exact commands attempted and that verification remains environment-blocked.
