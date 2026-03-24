# Worker Task Page Size Query Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update worker task fetching to send `page_size` instead of `limit`, with tests proving the request contract.

**Architecture:** Keep the change local to `TaskRemoteDataSource`. Add a focused datasource test that inspects captured query parameters, then rename the request argument and update callers to use `pageSize`.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Add request contract coverage

**Files:**
- Create: `test/features/dashboard/data/datasources/task_remote_data_source_test.dart`

**Step 1: Write the failing test**

- Assert that `fetchMyTasks()` sends `task_type`, `cursor`, and `page_size`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/datasources/task_remote_data_source_test.dart`

Expected: FAIL because the datasource still sends `limit`.

### Task 2: Update worker task request parameter

**Files:**
- Modify: `lib/features/dashboard/data/datasources/task_remote_data_source.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write minimal implementation**

- Rename `limit` to `pageSize` in `fetchMyTasks()`.
- Send `page_size` in the query map.
- Update any call sites and fake implementations to use the renamed argument.

**Step 2: Run focused tests**

Run: `flutter test test/features/dashboard/data/datasources/task_remote_data_source_test.dart`
Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`

Expected: PASS

### Task 3: Clean up

**Files:**
- Modify: touched files only

**Step 1: Format**

Run: `dart format lib/features/dashboard/data/datasources/task_remote_data_source.dart test/features/dashboard/data/datasources/task_remote_data_source_test.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 2: Final verification**

Run the focused tests again and confirm they stay green.
