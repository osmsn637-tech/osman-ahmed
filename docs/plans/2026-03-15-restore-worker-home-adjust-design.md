# Restore Worker Home Adjust Design

**Date:** 2026-03-15

## Goal

Restore the `Adjust` quick action on the worker home page without removing the newer task-based adjustment flow in worker task details.

## Decision

- Add `Adjust` back as a second worker-home quick action.
- Reuse the existing shared scan dialog.
- Route scanned barcodes to the existing item lookup result route with `?mode=adjust`.
- Keep the task-details adjustment flow unchanged.
- Keep the existing `/adjustment` route in More unchanged.

## Impact

- Worker home regains the old visible adjustment entry point.
- The newer adjustment task implementation remains available for task-driven work.
- Regression coverage should verify both `Lookup` and `Adjust` are visible on worker home.
