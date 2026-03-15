# Cycle Count Two-Page Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current cycle count form with a two-page scan-driven flow that supports per-item counting and `Continue later` resume for both cycle count modes.

**Architecture:** Keep cycle count inside the existing worker task details route, but normalize both cycle count modes into a single per-item progress model. Persist partial progress into task `workflowData` through a new save-progress repository path so the task details screen can rehydrate saved state after refresh or reopen.

**Tech Stack:** Flutter, Provider, flutter_test

---

### Task 1: Add cycle count progress parsing to task entities

**Files:**
- Modify: `lib/features/dashboard/domain/entities/task_entity.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that reopens a cycle count task with preloaded `workflowData['cycleCountProgress']` and expects the counted item state to render as already completed.

Use test data like:

```dart
workflowData: const {
  'cycleCountMode': 'full_shelf',
  'expectedLines': [
    {'itemName': 'Blue Mug', 'barcode': 'SKU-001', 'expectedQuantity': 4},
    {'itemName': 'Red Mug', 'barcode': 'SKU-002', 'expectedQuantity': 2},
  ],
  'cycleCountProgress': {
    'items': [
      {
        'key': 'SKU-001',
        'barcode': 'SKU-001',
        'countedQuantity': 5,
        'completed': true,
      },
    ],
  },
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count restores saved progress when reopened"`
Expected: FAIL because `TaskEntity` does not expose normalized cycle count items or saved progress yet.

**Step 3: Write minimal implementation**

In `task_entity.dart`, add small value types and getters for normalized cycle count state:

```dart
class CycleCountItem {
  const CycleCountItem({
    required this.key,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
  });

  final String key;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
}

class CycleCountProgressItem {
  const CycleCountProgressItem({
    required this.key,
    required this.barcode,
    required this.countedQuantity,
    required this.completed,
  });

  final String key;
  final String barcode;
  final int countedQuantity;
  final bool completed;
}
```

Add getters that:

- convert `single_item` into one normalized item
- convert `full_shelf` expected lines into normalized items
- parse `workflowData['cycleCountProgress']`
- use barcode as the primary stable key and fall back to item name when needed

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count restores saved progress when reopened"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/domain/entities/task_entity.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add cycle count progress parsing"
```

### Task 2: Add partial progress persistence to the worker task stack

**Files:**
- Modify: `lib/features/dashboard/domain/repositories/task_repository.dart`
- Modify: `lib/features/dashboard/domain/usecases/complete_task_usecase.dart`
- Create: `lib/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_mock.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Test: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add a repository test that:

1. loads a cycle count task
2. saves `cycleCountProgress`
3. reloads tasks
4. expects the same task to still include saved progress in `workflowData`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "save cycle count progress persists in local task overlay"`
Expected: FAIL because no save-progress method exists.

**Step 3: Write minimal implementation**

Extend the repository contract with:

```dart
Future<TaskEntity> saveCycleCountProgress(
  int taskId, {
  required Map<String, Object?> progress,
});
```

Add a use case and controller method:

```dart
Future<TaskEntity> saveCycleCountProgress(
  int taskId, {
  required Map<String, Object?> progress,
}) async {
  final updated = await _saveCycleCountProgress.execute(
    taskId,
    progress: progress,
  );
  await load();
  return updated;
}
```

Repository rules:

- mock repo updates the matching task in `_store`
- impl repo resolves the task, clones it, and writes updated `workflowData`
- impl repo stores the updated task in `_localTasks` so later `getTasksForZone()` calls return the resumed state

Use a helper merge like:

```dart
final nextWorkflowData = Map<String, Object?>.from(existing.workflowData)
  ..['cycleCountProgress'] = progress;
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "save cycle count progress persists in local task overlay"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/complete_task_usecase.dart lib/features/dashboard/domain/usecases/save_cycle_count_progress_usecase.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/features/dashboard/data/repositories/task_repository_mock.dart lib/features/dashboard/data/repositories/task_repository_impl.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart
git commit -m "feat: persist cycle count progress"
```

### Task 3: Replace the inline cycle count form with page 1 list flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add a widget test for each mode that expects:

- cycle count opens on a list page
- the worker can scan an item barcode
- a matching scan navigates to item detail page 2
- an unknown barcode shows an error and stays on page 1

Suggested test names:

- `single-item cycle count uses scan-first list page`
- `full-shelf cycle count unknown barcode stays on list page`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "single-item cycle count uses scan-first list page"`
Expected: FAIL because the page still renders the old inline inputs.

**Step 3: Write minimal implementation**

Refactor cycle count state in `worker_task_details_page.dart`:

- remove `_cycleCountQuantityController`, `_cycleCountLineControllers`, and unexpected-item-only gating from the active flow
- add cycle count state:

```dart
int _cycleCountPage = 0;
String? _selectedCycleCountItemKey;
String? _cycleCountScanError;
bool _savingCycleCountProgress = false;
late List<_CycleCountItemState> _cycleCountItems;
```

- initialize `_cycleCountItems` from `task.cycleCountItems` plus saved progress
- page 1 renders the shelf, progress summary, scan button/popup, and item list
- item rows show expected quantity, saved counted quantity, and counted/pending status
- scanning uses `showItemLookupScanDialog()` and matches against normalized item barcodes
- matched scan sets `_selectedCycleCountItemKey` and `_cycleCountPage = 1`
- unknown scan sets `_cycleCountScanError`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "single-item cycle count uses scan-first list page"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add cycle count list page"
```

### Task 4: Add page 2 item detail and confirm flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add widget tests that:

- open page 2 by scanning an item
- show lookup-style item detail content
- allow entering a counted quantity
- confirm the quantity
- return to page 1 with the item marked counted
- reopen the same item and show the saved quantity for editing

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count item detail confirms quantity and returns to list"`
Expected: FAIL because page 2 and confirm/save logic do not exist.

**Step 3: Write minimal implementation**

In `worker_task_details_page.dart`, add a page 2 builder that reuses the lookup-result visual shape with current task data:

```dart
Widget _buildCycleCountItemDetailPage(BuildContext context, _CycleCountItemState item) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.itemName),
      Text(item.barcode),
      Text('Expected: ${item.expectedQuantity}'),
      TextField(
        key: const Key('cycle-count-detail-quantity-field'),
        controller: _cycleCountDetailQuantityController,
        keyboardType: TextInputType.number,
      ),
      ElevatedButton(
        key: const Key('cycle-count-detail-confirm-button'),
        onPressed: _confirmCycleCountItem,
        child: const Text('Confirm quantity'),
      ),
    ],
  );
}
```

Confirm logic:

- validate positive quantity
- update selected item counted quantity
- build `cycleCountProgress` payload
- call `onSaveCycleCountProgress`
- return to page 1

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count item detail confirms quantity and returns to list"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add cycle count detail confirmation page"
```

### Task 5: Add continue-later resume flow and final completion gating

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add widget tests that:

- count one item
- tap `Continue later`
- reopen the task
- see saved progress restored
- verify completion stays disabled until all items are confirmed
- verify completion sends the summed counted quantity and shelf location

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count continue later restores progress and gates completion"`
Expected: FAIL because there is no continue-later action or saved resume state in the details flow.

**Step 3: Write minimal implementation**

Add to `WorkerTaskDetailsPage`:

- new optional callback:

```dart
final Future<void> Function(
  int taskId, {
  required Map<String, Object?> progress,
})? onSaveCycleCountProgress;
```

- a `Continue later` button on page 1 that saves the current progress payload and pops the screen
- completion gating based on `every((item) => item.completed)`
- final completion quantity as:

```dart
final totalCounted = _cycleCountItems.fold<int>(
  0,
  (sum, item) => sum + item.countedQuantity,
);
```

Wire `worker_home_page.dart` so the details screen receives:

```dart
onSaveCycleCountProgress: (taskId, {required progress}) =>
    controller.saveCycleCountProgress(taskId, progress: progress),
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "cycle count continue later restores progress and gates completion"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart lib/features/dashboard/presentation/pages/worker_home_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add resumable cycle count flow"
```
