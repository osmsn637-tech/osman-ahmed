# Task Units Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show a unit next to every task quantity on the worker task pages, using the API-provided unit and falling back to `pc` when it is missing.

**Architecture:** Add a normalized `unit` field to `TaskEntity` and parse it once in `TaskRepositoryImpl` from both unified and legacy task payloads. Centralize quantity formatting on the entity so `WorkerHomePage` and `WorkerTaskDetailsPage` render the same `"<quantity> <unit>"` text without duplicating fallback logic.

**Tech Stack:** Flutter, Dart, provider, Flutter widget tests

---

### Task 1: Add failing repository and UI tests

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing repository test**

Add a task payload with `unit` from the API and assert `TaskEntity.unit` is parsed.

**Step 2: Run the focused repository test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "parses task unit from API payload"`
Expected: FAIL because `TaskEntity` has no unit support yet.

**Step 3: Write the failing worker home/details tests**

Assert task cards and quantity summaries render `12 box` / `12 pc` instead of raw `12`.

**Step 4: Run the focused widget tests to verify they fail**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart --plain-name "worker home task card shows quantity with unit"`
Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "generic task hero shows labeled quantity summary with unit"`
Expected: FAIL because the pages still render plain numbers.

### Task 2: Add normalized unit support to task entities and repository mapping

**Files:**
- Modify: `lib/features/dashboard/domain/entities/task_entity.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `test/support/fake_repositories.dart`

**Step 1: Add the normalized field and formatter**

Extend `TaskEntity` with a nullable raw `unit`, a normalized getter that falls back to `pc`, and a quantity formatter for task and nested task-item quantities.

**Step 2: Parse unit from remote payloads**

Read unit values from task-level, detail-level, product-level, and legacy payload fields, then propagate them through `_cloneTask`.

**Step 3: Update fake/test task builders**

Allow tests to pass unit values and keep the fallback behavior stable in helpers.

### Task 3: Render units across worker task pages

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Replace raw task quantity text**

Update task cards, hero summary, task info rows, refill/receive quantities, return line quantities, and cycle-count counted text to use the shared quantity formatter.

**Step 2: Preserve input controls**

Keep editable quantity text fields numeric-only; only change display strings and helper text labels.

### Task 4: Verify the change

**Files:**
- No code changes expected

**Step 1: Run focused repository verification**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 2: Run focused worker page verification**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 3: Run targeted analysis if the environment allows**

Run: `flutter analyze lib/features/dashboard/domain/entities/task_entity.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
