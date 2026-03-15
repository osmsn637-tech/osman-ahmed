# Worker Task Visibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Surface all API-returned worker task categories in the worker queue and display normalized labels that match the app's task language.

**Architecture:** Keep repository parsing and workflow branching on the existing `TaskType` enum, but separate two concerns that are currently conflated: zone inference and user-facing type labels. Tighten zone inference so non-zone subtitles do not hide tasks, and introduce an explicit display-label helper for task badges/details.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock mixed-task queue visibility with a failing repository test

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add a test with mixed `putaway`, `restock`, and `return` worker tasks where `restock` and `return` only have non-zone subtitles.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
Expected: FAIL because only the task with a derivable zone survives `getTasksForZone('Z01')`.

**Step 3: Write minimal implementation**

Adjust zone derivation/matching in `TaskRepositoryImpl` so worker-scoped tasks without a derived zone are still returned.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
Expected: PASS

### Task 2: Lock normalized task labels with a failing widget test

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `lib/features/dashboard/presentation/shared/task_visuals.dart`
- Modify: `lib/features/dashboard/presentation/shared/dashboard_common_widgets.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing test**

Add widget assertions proving `TaskType.returnTask` renders as `RETURN` and `TaskType.refill` renders as `REFILL`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL because the UI currently renders `RETURNTASK`.

**Step 3: Write minimal implementation**

Add a single task-type label helper and replace direct `type.name.toUpperCase()` usage.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

### Task 3: Run focused verification

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/presentation/shared/task_visuals.dart`
- Modify: `lib/features/dashboard/presentation/shared/dashboard_common_widgets.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Run focused verification**

Run:

```bash
flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
```

Expected: both commands pass cleanly.
