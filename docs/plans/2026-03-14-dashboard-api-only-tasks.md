# Dashboard API-Only Tasks Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove seeded mock dashboard tasks and local dashboard task creation so worker tasks come only from API-backed responses.

**Architecture:** Keep `TaskRepositoryImpl` as a parser and cache for remote tasks, plus local state overlays for real task progress. Remove the mock seeding path and delete the repository contract and use case that allow local task creation.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock repository behavior with tests

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add assertions that:

- `getTasksForZone('Z03')` returns only remote tasks and does not inject return/cycle-count placeholders.
- `getTasksForZone('Z03')` returns an empty list when the API returns an empty list.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
Expected: FAIL because seeded mock tasks are still present.

**Step 3: Write minimal implementation**

Remove mock seeding and mock-only handling from `TaskRepositoryImpl`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add test/features/dashboard/data/repositories/task_repository_impl_test.dart lib/features/dashboard/data/repositories/task_repository_impl.dart
git commit -m "refactor: remove dashboard mock task overlay"
```

### Task 2: Remove local dashboard task creation from the contract

**Files:**
- Modify: `lib/features/dashboard/domain/repositories/task_repository.dart`
- Delete: `lib/features/dashboard/domain/usecases/route_task_from_event_usecase.dart`
- Delete: `test/features/dashboard/domain/usecases/route_task_from_event_usecase_test.dart`
- Modify: `test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

**Step 1: Write the failing test**

Use compile/test failures from contract users as the failing signal after removing `createTask` from the interface.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
Expected: FAIL until fake repositories and code paths are updated.

**Step 3: Write minimal implementation**

- Remove `createTask` from the repository interface.
- Remove the event-routing use case and tests that depend on it.
- Update fake repositories in remaining tests to match the new interface.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/route_task_from_event_usecase.dart test/features/dashboard/domain/usecases/route_task_from_event_usecase_test.dart test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart
git commit -m "refactor: remove local dashboard task creation"
```

### Task 3: Clean remaining task tests and verify

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

**Step 1: Write the failing test**

Update or remove expectations that rely on default placeholder dashboard tasks.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Expected: FAIL if any test still assumes auto-seeded mock tasks.

**Step 3: Write minimal implementation**

Make the tests explicitly create fixtures when they need tasks and remove expectations tied to seeded placeholders.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart
git commit -m "test: remove dashboard placeholder task assumptions"
```

### Task 4: Final targeted verification

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/domain/repositories/task_repository.dart`

**Step 1: Run focused verification**

Run:

```bash
flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart
flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart
flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart
flutter analyze lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/domain/repositories/task_repository.dart
```

Expected: all commands pass cleanly.

**Step 2: If a command fails**

Write the next failing test or make the minimal fix, then rerun the same command.

**Step 3: Commit**

```bash
git add lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/domain/repositories/task_repository.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart
git commit -m "refactor: source dashboard tasks from api only"
```
