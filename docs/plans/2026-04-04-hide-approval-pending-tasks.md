# Hide Approval-Pending Tasks Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove approval-pending completed tasks from the worker task lists everywhere they are consumed.

**Architecture:** Detect approval-pending raw task statuses in the dashboard repository while parsing remote tasks, and filter those tasks out before controller-level current/completed splitting. Cover the behavior with repository-focused tests so UI counts and sections inherit the rule automatically.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Add a failing repository regression test

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Test: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

```dart
test('filters approval-pending completed tasks from the worker queue', () async {
  // build remote payload with one normal task and one approval-pending completed task
  // expect only the normal task to remain
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "filters approval-pending completed tasks from the worker queue"`
Expected: FAIL until repository filtering is implemented.

**Step 3: Write minimal implementation**

Implement repository parsing/filtering logic to recognize approval-pending post-completion statuses and omit those tasks.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "filters approval-pending completed tasks from the worker queue"`
Expected: PASS

**Step 5: Commit**

```bash
git add test/features/dashboard/data/repositories/task_repository_impl_test.dart lib/features/dashboard/data/repositories/task_repository_impl.dart
git commit -m "fix: hide approval-pending completed tasks"
```

### Task 2: Verify dashboard task filtering stays green

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Test: `test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

**Step 1: Run focused repository and controller tests**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
Expected: PASS

**Step 2: Run formatter**

Run: `dart format lib/features/dashboard/data/repositories/task_repository_impl.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart`
Expected: Files formatted successfully

**Step 3: Commit**

```bash
git add lib/features/dashboard/data/repositories/task_repository_impl.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart
git commit -m "test: cover approval-pending task filtering"
```
