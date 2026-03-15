# Mock Putaway Cycle Count And Return Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add mock `cycle count` and `return` worker tasks with guided task-detail workflows so the team can iterate on the logic and operational UX.

**Architecture:** Extend the existing dashboard task model with lightweight workflow metadata, seed the mock repository with representative tasks, and branch `WorkerTaskDetailsPage` into dedicated `cycle count` and `return` flows. Keep all navigation and completion wiring inside the current worker dashboard pipeline.

**Tech Stack:** Flutter, Provider, existing dashboard presentation layer, `flutter_test`

---

### Task 1: Add failing tests for seeded mock tasks and new detail flows

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing tests**

Add tests that assert:
- mock queue includes `cycle count` and `return` tasks
- single-item cycle count requires location scan, item scan, and counted quantity before completion
- full-shelf cycle count shows expected lines and supports adding an unexpected item line
- return flow requires tote scan, item scan, quantity confirmation, and destination scan before completion

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the page does not yet render these workflows.

**Step 3: Write minimal implementation**

Implement only enough task metadata and UI branching to satisfy the new tests.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS

**Step 5: Commit**

```bash
git add test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart
git commit -m "test: add cycle count and return task flow coverage"
```

### Task 2: Extend task metadata and seed mock tasks

**Files:**
- Modify: `lib/features/dashboard/domain/entities/task_entity.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_mock.dart`
- Modify as needed: files that clone or construct `TaskEntity`

**Step 1: Add workflow metadata**

Support enough metadata to describe:
- cycle count mode
- return tote/container id
- cycle count expected lines

**Step 2: Seed realistic mock tasks**

Ensure the default mock zone includes:
- one return task
- one single-item cycle count task
- one full-shelf cycle count task

**Step 3: Keep existing task constructors compiling**

Update clone and fallback paths so metadata is preserved safely.

**Step 4: Run focused tests**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

Expected: PASS with the new seeded tasks available alongside existing flows.

**Step 5: Commit**

```bash
git add lib/features/dashboard/domain/entities/task_entity.dart lib/features/dashboard/data/repositories/task_repository_mock.dart
git commit -m "feat: seed mock cycle count and return tasks"
```

### Task 3: Implement multi-item return task details flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Render the return-specific workflow**

Page 1 shows:
- return item list
- scan/validate action per item line
- quantity per line
- item name with small barcode text
- image on the right
- `Return` action enabled only after all item lines are validated

Page 2 shows:
- one editable section per item line
- item name
- barcode
- destination location
- location scan/entry field
- quantity entry field

**Step 2: Gate completion**

Require:
- all page 1 item lines are validated before entering page 2
- every page 2 item line has a valid destination scan
- every page 2 item line has a valid quantity

**Step 3: Pass completion values**

Use the aggregate processed quantity and the last resolved destination location when calling the completion callback for the mock task.

**Step 4: Run focused tests**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS for multi-item return coverage.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add mock return task workflow"
```

### Task 4: Implement cycle count task details flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Render single-item count flow**

Require:
- shelf scan
- item scan
- counted quantity entry
- variance summary

**Step 2: Render full-shelf count flow**

Require:
- shelf scan
- expected line list
- counted quantities per line
- optional unexpected item line entry
- variance review

**Step 3: Gate completion**

Allow completion only when the required fields for the active mode are ready.

**Step 4: Run focused tests**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS for both cycle count modes.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add mock cycle count task workflows"
```

### Task 5: Verify and regressions

**Files:**
- Modify only if needed: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify only if needed: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Run targeted tests**

Run:
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`

Expected: PASS

**Step 2: Format touched files**

Run:
- `dart format lib/features/dashboard/domain/entities/task_entity.dart lib/features/dashboard/data/repositories/task_repository_mock.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart docs/plans/2026-03-14-mock-putaway-cycle-return-design.md docs/plans/2026-03-14-mock-putaway-cycle-return.md`

**Step 3: Commit**

```bash
git add docs/plans/2026-03-14-mock-putaway-cycle-return-design.md docs/plans/2026-03-14-mock-putaway-cycle-return.md lib/features/dashboard/domain/entities/task_entity.dart lib/features/dashboard/data/repositories/task_repository_mock.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart
git commit -m "feat: add mock cycle count and return workflows"
```
