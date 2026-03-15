# Cycle Count Two-Page Flow Design

## Summary

Replace the current inline cycle count form with a two-page worker flow for both `single_item` and `full_shelf` cycle count tasks.

Page 1 is the cycle count queue for the current shelf. It shows the shelf, the list of items to count, each item's progress state, a scan entry point, and a `Continue later` action. When the worker scans an item barcode, the flow opens page 2 for that item.

Page 2 reuses the visual structure of the lookup result view, but changes the action model from read-only lookup to editable counting. The worker sees the item details, current shelf information, and an editable counted quantity field. Confirming the quantity saves progress and returns the worker to page 1. The worker repeats that until every item is counted, then completes the task.

## Goals

- Make cycle count feel scan-driven instead of form-driven.
- Use the same flow for both cycle count modes.
- Let workers stop mid-task and resume exactly where they left off.
- Keep the existing task details route and completion wiring.

## Non-Goals

- No new top-level route for cycle count.
- No backend API redesign in this step.
- No expansion into unexpected-item authoring beyond the countable list already present in the task.

## Current State

Cycle count is currently embedded inside [worker_task_details_page.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/dashboard/presentation/pages/worker_task_details_page.dart). Single-item mode uses a validated location, validated product, and one counted quantity field. Full-shelf mode renders expected lines inline and asks the worker to type counted quantities directly in the list.

This has three problems:

1. It is inconsistent across cycle count modes.
2. It is not optimized for scan-first work.
3. It has no explicit partial-progress save/resume path.

## Proposed Architecture

### Task Normalization

Both cycle count modes will be normalized into a countable item list derived from `TaskEntity`.

- `single_item` becomes a one-item list using the task's own `itemName`, `itemBarcode`, and expected quantity.
- `full_shelf` uses `workflowData['expectedLines']`.

Each normalized item will carry:

- stable item key
- item name
- barcode
- expected quantity
- counted quantity
- completion state

Progress will be stored back into `workflowData` under a dedicated cycle count progress key so the same `TaskEntity` can rehydrate the flow after refresh or reopen.

### Page 1: Cycle Count Hub

Page 1 replaces the existing cycle count form body.

It shows:

- shelf location
- cycle count progress summary, for example `2 of 5 counted`
- scan entry via the shared lookup popup
- list of expected items with counted/pending status
- action to open an already-counted item again for correction
- `Continue later` button

Scan behavior:

- a matching barcode opens page 2 for that item
- an unknown barcode stays on page 1 and shows an error message
- scanning an already-counted item reopens page 2 with its saved quantity

### Page 2: Count Item Detail

Page 2 is an internal detail state inside the same task details screen, not a new route.

It uses the lookup-result presentation style:

- item identity
- barcode
- shelf/bulk location summary when available
- image if available
- expected quantity

It adds cycle-count-specific controls:

- editable shelf quantity field
- confirm button
- back action to return to page 1 without changing progress

Confirming:

- validates that quantity is a positive integer
- updates local cycle count progress state
- saves progress through the worker task stack
- returns to page 1

### Resume Model

`Continue later` saves current progress and exits the details screen without completing the task.

Resume works by persisting cycle count progress in `workflowData` and updating the locally cached task record in both repository implementations.

- mock repository updates the in-memory `_store`
- task repository implementation updates the local overlay task in `_localTasks`

Because `getTasksForZone()` already merges local tasks with remote tasks, this local overlay is enough for resume in the current architecture.

## Data Flow

1. Worker opens a cycle count task.
2. Task details page normalizes cycle count items and hydrates any saved progress from `workflowData`.
3. Worker scans an item from page 1.
4. Page 2 opens for that item and shows lookup-style details.
5. Worker confirms counted quantity.
6. Page state updates locally, then calls a new save-progress callback.
7. Repository persists progress into the task's `workflowData`.
8. Worker returns to page 1 and continues.
9. When all items are confirmed, the existing complete-task path becomes enabled.

## State Changes

The task details page needs a dedicated cycle count state model instead of the current field-controller-only approach.

Recommended state:

- current cycle count page index or selected item key
- list of normalized count items
- saved counted quantities
- page-level error message for bad scans
- save-in-progress flag for `Continue later` and per-item confirm

`TaskEntity` should expose helper getters for:

- normalized cycle count items
- cycle count progress entries from `workflowData`
- whether all count items are complete

## Persistence Shape

Recommended `workflowData` addition:

```json
{
  "cycleCountProgress": {
    "items": [
      {
        "key": "SKU-001",
        "barcode": "SKU-001",
        "countedQuantity": 5,
        "completed": true
      }
    ],
    "updatedAt": "2026-03-14T00:00:00Z"
  }
}
```

Single-item tasks use the same shape with one item.

## Error Handling

- Unknown scan: show an inline error on page 1 and keep focus ready for another scan.
- Empty or invalid quantity on page 2: show field error and do not save.
- Save-progress failure: keep the worker on the current page and show a retryable message.
- Reopening an already-counted item: preload the saved quantity so it can be edited.

## Completion Rules

- Cycle count cannot complete until every normalized item has a confirmed counted quantity.
- The final completion call can still use the existing `completeTask` path.
- Final submitted quantity should be the sum of counted quantities for the normalized list.
- Submitted location remains the cycle count shelf.

## Testing Strategy

Add widget coverage for:

- single-item cycle count using the new two-page scan flow
- full-shelf cycle count using the same flow
- unknown barcode handling
- editing an already-counted item
- `Continue later` saving progress and restoring it on reopen
- completion remaining disabled until all items are confirmed

Add repository coverage for:

- saving cycle count progress in mock storage
- preserving saved cycle count progress in the local overlay repository

## Risks

- The current task details page is large, so adding the two-page state inline can make it harder to maintain. This should be managed by extracting cycle-count-specific helpers or widgets while keeping the route intact.
- Remote tasks currently have no partial-save API, so resume depends on local overlay state. That is acceptable for this step but should be revisited if multi-device resume becomes required.
