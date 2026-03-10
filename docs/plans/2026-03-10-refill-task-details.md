# Refill Task Details Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign refill task details into a two-screen bulk-to-shelf flow that preloads lookup data, validates the item barcode first, then validates shelf location and manual quantity before completion.

**Architecture:** Keep the existing worker task details entry point, but branch refill tasks into a dedicated flow. Reuse the existing item lookup capability to fetch route data on open, then drive the refill UX with explicit state transitions: loading, barcode validation, shelf validation, quantity validation, and completion.

**Tech Stack:** Flutter, Provider, existing dashboard/task presentation layer, `flutter_test`

---

### Task 1: Add failing tests for the refill-specific flow

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing test**

Add refill-focused widget tests that assert:
- refill task enters a dedicated flow instead of the generic task layout
- lookup loading state appears on open
- lookup success renders image, item name, barcode, and bulk location on screen 1
- correct barcode validation advances to screen 2
- screen 2 shows shelf location, manual quantity field, and disabled complete button until valid
- non-refill tasks still use the current behavior

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the current refill flow is a single generic screen and does not preload lookup data.

**Step 3: Write minimal implementation**

Implement only enough refill-specific state and UI branching to satisfy the tests.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS

**Step 5: Commit**

```bash
git add test/features/dashboard/presentation/pages/worker_task_details_page_test.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart
git commit -m "feat: redesign refill task details flow"
```

### Task 2: Load lookup data immediately for refill tasks

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Inspect as reference only: `lib/features/move/presentation/controllers/item_lookup_controller.dart`
- Inspect as reference only: `lib/features/move/domain/usecases/lookup_item_by_barcode_usecase.dart`

**Step 1: Add refill lookup lifecycle**

When `task.type == TaskType.refill`:
- read `task.itemBarcode`
- trigger lookup immediately in `initState` or an equivalent lifecycle hook

Track states:
- loading
- success
- error

**Step 2: Handle missing barcode**

If barcode is missing:
- enter a blocking error state
- do not allow refill progress

**Step 3: Map lookup result into refill route data**

Extract:
- bulk location
- shelf location
- item image if lookup data should override the task image

**Step 4: Run focused test**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: refill tests reach the loading and success/error states correctly.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart
git commit -m "feat: preload lookup data for refill tasks"
```

### Task 3: Build refill screen 1 for bulk barcode validation

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Render the first refill screen**

Show only:
- image
- item name
- barcode
- bulk location
- barcode validation field

**Step 2: Gate navigation on barcode validation**

When scanned barcode matches task barcode:
- mark barcode step valid
- navigate to refill screen 2

When mismatch occurs:
- show mismatch feedback
- remain on screen 1

**Step 3: Run focused test**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: barcode validation advances only on a correct scan.

**Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add refill bulk barcode validation screen"
```

### Task 4: Build refill screen 2 for shelf validation and quantity entry

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Render the second refill screen**

Show:
- shelf location
- location validation field
- manual quantity input
- complete action

**Step 2: Enforce completion rules**

Allow completion only when:
- shelf location is validated
- quantity is a valid positive integer
- quantity is not greater than `task.quantity`

Use the entered quantity when calling the completion callback.

**Step 3: Handle invalid states**

Show feedback for:
- wrong shelf location
- empty quantity
- non-numeric quantity
- quantity greater than allowed task quantity

**Step 4: Run focused test**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: complete action remains disabled until all conditions pass.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add refill shelf validation and quantity flow"
```

### Task 5: Preserve non-refill behavior and finalize tests

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Add regression coverage**

Verify:
- receive flow remains separate
- move and other task types still use existing behavior

**Step 2: Keep branching isolated**

Do not rewrite generic flows beyond what refill requires.

**Step 3: Run focused tests**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS for refill and existing task types.

**Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "test: cover refill and existing task detail flows"
```
