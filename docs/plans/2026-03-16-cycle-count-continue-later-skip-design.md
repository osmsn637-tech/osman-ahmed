# Cycle Count Continue Later Skip Design

**Date:** 2026-03-16

## Goal

Make cycle count `Continue Later` save counted products, call the worker skip endpoint, and return the task to the worker homepage as a pending task that can be reopened with its counted products restored.

## Current State

- `Continue Later` only saves `cycleCountProgress` locally in memory.
- The worker page pops after that local save, but no backend skip action is sent.
- The repository currently prefers the full cached local task over the fresh remote task on reload, which is the wrong merge strategy for this flow.

## Approved Design

### Continue later behavior

- Keep building the same `cycleCountProgress` payload from the worker task page.
- Add a dedicated continue-later callback for cycle count.
- That callback should:
  - save `cycleCountProgress`
  - call the worker `skipTask` endpoint with `task_type: cycle_count`
  - reload tasks

### Refresh behavior

- When fresh remote tasks are fetched, the remote task should remain the source of truth for status and assignment.
- For cycle count tasks only, merge any locally saved `workflowData['cycleCountProgress']` onto the fresh remote task before returning it.
- Do not preserve the entire cached local task over the remote task.

### Expected result

- After `Continue Later`, the task appears as `pending`.
- Reopening the same cycle count task restores counted products, counted quantities, and validated location from `cycleCountProgress`.

## Scope

- Add skip support to the task repository/controller path.
- Update the worker task page continue-later callback wiring.
- Adjust repository merge behavior for cached cycle count progress.

## Testing

- Repository test: cycle count skip calls `skipTask` with `task_type: cycle_count`.
- Repository test: after local cycle count progress is saved, a fresh remote fetch still returns the task with merged `cycleCountProgress`.
- Controller or widget-facing regression: continue later returns the task to pending while preserving progress for reopen.
