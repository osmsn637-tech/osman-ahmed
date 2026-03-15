# Adjustment Task Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the lookup-based worker adjustment flow with an API-backed adjustment task flow in dashboard task details, using increase/decrease delta math and the mobile adjustment endpoints.

**Architecture:** Keep dashboard tasks as the entry point for all worker execution flows. Add dedicated adjustment-task models and API calls for scan-location and count submission, then render a task-specific adjustment flow in `WorkerTaskDetailsPage` that computes `actualQuantity` locally before submit. Remove the old lookup-result adjustment route from the worker home flow so production adjustment behavior is task-based only.

**Tech Stack:** Flutter, Provider, existing dashboard repository layer, existing API client, Flutter widget tests

---

### Task 1: Document and isolate the old lookup-based adjust flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- Test: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing tests**

Add/update tests so worker-home no longer routes the `Adjust` action into lookup-result adjust mode, and so lookup mode remains read-only in production.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 3: Write minimal implementation**

Remove or repurpose the worker-home `Adjust` action so production adjustment entry comes from dashboard tasks, not the lookup route.

**Step 4: Run tests to verify they pass**

Re-run the same targeted tests.

### Task 2: Add adjustment task API models and datasource support

**Files:**
- Create: `lib/features/dashboard/domain/entities/adjustment_task_entities.dart`
- Modify: `lib/features/move/domain/entities/stock_adjustment_params.dart`
- Modify: `lib/features/move/data/datasources/item_remote_data_source.dart`
- Modify: `lib/features/move/data/repositories/item_repository_impl.dart`
- Modify: `lib/features/move/data/repositories/item_repository_mock.dart`
- Test: `test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 1: Write the failing tests**

Add focused tests for:
- increase/decrease delta math
- submit payload using `actualQuantity`
- no-negative decrease guard

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 3: Write minimal implementation**

Add request fields needed for task-based submission and the remote datasource methods for:
- scanning an adjustment location
- submitting an adjustment item count

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

### Task 3: Replace the old item adjustment controller with task-based state

**Files:**
- Modify: `lib/features/move/presentation/controllers/item_adjustment_controller.dart`
- Test: `test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 1: Write the failing tests**

Add tests covering:
- selecting a scanned adjustment product
- switching between increase and decrease
- updating delta quantity
- computing preview quantity from current system quantity
- blocking submit when decrease would go below zero

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 3: Write minimal implementation**

Refactor controller state around:
- selected adjustment item
- operation mode
- delta quantity
- preview quantity
- note
- submit state

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

### Task 4: Add the adjustment task flow to worker task details

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add widget tests that:
- open an adjustment task
- scan a location
- show returned products
- select a product
- choose decrease
- enter a delta
- show `current -> new`
- submit and mark the item counted

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "adjustment task"`

**Step 3: Write minimal implementation**

Render a dedicated adjustment branch in task details with:
- location scan
- scanned products list
- count status
- operation toggle
- delta stepper/input
- preview summary
- submit action

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "adjustment task"`

### Task 5: Verify integrated behavior and keep lookup mode read-only

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add regression assertions that:
- lookup result page does not expose production adjustment flow
- worker home still supports lookup scan
- adjustment behavior exists only inside task details

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 3: Write minimal implementation**

Clean up any remaining adjust-route assumptions and keep lookup behavior read-only.

**Step 4: Run test to verify it passes**

Re-run the same targeted tests.

### Task 6: Final verification

**Files:**
- Verify only

**Step 1: Run targeted tests**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 2: Run analyzer**

Run: `flutter analyze`

**Step 3: Confirm results**

Record any remaining pre-existing warnings or infos separately from new failures.
