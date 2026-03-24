# Worker Complete Fallback Design

Date: 2026-03-15

## Goal

Fix worker task completion for API-backed `receiving`, `return`, and `cycle_count` tasks when the `/complete` endpoint rejects the request.

## Problem

The worker details screen calls the shared completion flow for all task types. For `receiving`, `return`, and `cycle_count`, the repository currently sends only the `/complete` request. If that endpoint rejects the request for a given task type, the UI catches the exception and leaves the task open.

The current details page also hides the backend failure details by replacing the mapped exception with a generic "Failed to complete task" message.

## Chosen approach

Use a guarded repository fallback:

- For `receiving`, `return`, and `cycle_count`, try the existing `/complete` endpoint first.
- If `/complete` fails with a contract-style backend error, retry using the submit flow with the available quantity and location data.
- Preserve the existing behavior for adjustment tasks and for task types that already use `submit` followed by `complete`.

Also preserve the actual mapped error message so the details page can show the backend reason instead of a generic failure string.

## Why this approach

- It is the smallest change that addresses the user-reported broken task types.
- It avoids assuming `/complete` is always wrong.
- It keeps the existing happy path intact where the direct complete call already works.
- It gives the UI enough information to show what the backend rejected.

## Scope

- `TaskRepositoryImpl.completeTask`
- repository tests for direct-complete task types
- worker task details error presentation

## Non-goals

- Changing the adjustment completion flow
- Reworking the putaway/restock completion contract
- Refactoring the entire worker task execution pipeline
