# Cycle Count Scan And Submit Design

**Date:** 2026-03-16

## Goal

Make cycle count task scans hit the worker `scanTask` endpoint and make cycle count completion finish through the worker `submitTask` endpoint instead of the complete endpoint.

## Current State

- Cycle count location validation already uses the existing worker scan callback, which reaches `TaskRepository.validateTaskLocation(...)` and then `TaskRemoteDataSource.scanTask(...)`.
- Cycle count list-page item barcode scans are still handled locally inside `WorkerTaskDetailsPage` and never call the backend scan endpoint.
- `TaskRepositoryImpl.completeTask(...)` currently groups `cycle_count` with receiving and return tasks and tries `completeTask(...)` first, only falling back to `submitTask(...)` on certain backend errors.

## Approved Design

### Scan flow

- Keep the existing cycle count location validation flow unchanged.
- Update cycle count item barcode scans on the worker task page so they call the existing validation callback before opening the counted item.
- Treat a backend-valid scan as eligible to open the matching local cycle count item.
- Keep the local barcode-to-item matching after the backend call so the UI still opens the correct item and preserves the existing workflow.
- If the backend scan fails or returns invalid, show the existing scan error state and do not open an item.

### Completion flow

- Change repository completion routing for `cycle_count` so it calls `submitTask(...)` directly.
- Do not call `completeTask(...)` for `cycle_count`.
- Keep the current cycle count payload shape:
  - `task_type: cycle_count`
  - `quantity: total counted quantity`
  - `location_id: validated location text`

## Scope

- Modify cycle count endpoint routing in `TaskRepositoryImpl`.
- Update worker task details cycle count scan handling to use the backend scan callback for item scans.
- Add repository tests and worker task details widget coverage for the new routing.

## Non-Goals

- No changes to receiving, refill, return, adjustment, or putaway endpoint routing.
- No cycle count UI redesign.
- No changes to saved cycle count progress structure.

## Testing

- Repository test: cycle count completion uses `submitTask(...)` and does not call `completeTask(...)`.
- Widget test: cycle count list-page item scan invokes the scan callback and only opens the matching item after a valid backend response.
