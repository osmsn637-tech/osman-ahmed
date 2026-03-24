# Cycle Count Frontend-Only Item Scan Design

**Date:** 2026-03-16

## Goal

Make cycle count item barcode scans on the worker task page validate only against the frontend task data, without calling the backend scan endpoint.

## Current State

- Cycle count location validation still uses the worker scan callback.
- Cycle count item scans were recently changed to call the same backend validation callback before matching local cycle count items.
- That backend step can reject valid scans when the response shape does not include one of the expected validation keys, even when the item exists locally in the cycle count task.

## Approved Design

- Keep cycle count location validation unchanged.
- Revert cycle count item barcode scans to frontend-only matching.
- After location validation succeeds, the cycle count item scan should:
  - normalize the scanned barcode
  - compare it directly against the local cycle count items in the task
  - open the matching item immediately when found
  - show the existing “Scanned item is not in this cycle count list.” message when no local item matches
- Do not call the backend validation callback for cycle count item scans.

## Scope

- Modify only the cycle count item scan behavior in `WorkerTaskDetailsPage`.
- Keep repository completion routing and all non-cycle-count validation flows unchanged.

## Testing

- Update the full-shelf cycle count widget test so location validation still hits the callback once, but the subsequent item scan does not call it again.
