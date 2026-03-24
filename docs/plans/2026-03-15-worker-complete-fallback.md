# Worker Complete Fallback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore completion for worker `receiving`, `return`, and `cycle_count` tasks when the direct `/complete` endpoint fails, while surfacing the real backend error in the task details UI.

**Architecture:** Keep `TaskRepositoryImpl` as the single completion entry point. For direct-complete task types, attempt the existing `/complete` call first, then retry with `submitTask` only for contract-style exceptions. Let the original mapped error message propagate so the details page can display it.

**Tech Stack:** Flutter, Dart, flutter_test, Dio

---

### Task 1: Add the failing repository test

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add a test proving a `receiving` task still completes when `completeTask` throws a backend-style exception and `submitTask` succeeds.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "falls back to submit when receiving complete endpoint fails"`
Expected: FAIL because the repository currently throws instead of retrying.

### Task 2: Implement the minimal repository fallback

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`

**Step 1: Add minimal implementation**

- Keep `adjustment` unchanged.
- For `receiving`, `return`, and `cycle_count`, try `completeTask`.
- On a mapped server or validation failure, retry through `submitTask` using the resolved quantity and location values already available to the repository.

**Step 2: Run the repository test again**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "falls back to submit when receiving complete endpoint fails"`
Expected: PASS

### Task 3: Surface the backend message in the details page

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Keep the current completion flow but preserve the mapped message**

- When completion throws, use the exception message when available.
- Keep the existing generic fallback only when no better message exists.

**Step 2: Add or update a widget test if needed**

Use an existing details-page test or add one only if necessary to lock the message behavior.

### Task 4: Focused verification

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Run focused verification**

Run:

```bash
flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
```

Expected: the updated repository test passes and the details page tests stay green.
