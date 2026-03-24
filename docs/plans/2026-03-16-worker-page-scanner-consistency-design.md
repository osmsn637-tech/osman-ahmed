# Worker Page Scanner Consistency Design

**Date:** 2026-03-16

## Goal

Make worker task scanner inputs behave consistently by keeping them autofocus-ready, auto-clearing stale scanned text after 2 seconds, and ensuring the cycle count second-page barcode field stays scanner-friendly without blocking quantity after a successful validation.

## Decision

Keep the change inside `WorkerTaskDetailsPage`. Standardize the hidden scanner inputs used on worker task pages so they all reclaim focus after scan handling and clear stale raw text on a short timer. The cycle count second-page barcode field will use a separate validation state so quantity can stay enabled after the raw field text clears.

## Scope

In scope:
- hidden scanner inputs in worker task details pages
- cycle count second-page barcode capture
- stale scan text clearing after 2 seconds
- widget coverage for autofocus and clear behavior

Out of scope:
- non-worker pages like receive, move, or inbound
- repository or controller changes
- custom scanner/audio packages

## Behavior Rule

1. Worker task hidden scanner fields stay autofocus-capable and keep reclaiming focus when their section is active.
2. Raw scanned text in worker task hidden scanner inputs clears after 2 seconds if it has not changed.
3. The cycle count second-page barcode field follows the same scanner-ready and auto-clear behavior.
4. Successful cycle count second-page barcode validation persists as state even after the raw text clears, so quantity remains enabled.

## Testing Intent

- Verify the cycle count second-page barcode hidden field is autofocus-capable.
- Verify the cycle count second-page barcode field clears its raw text after 2 seconds.
- Verify quantity remains enabled after a correct cycle count barcode even when the raw barcode field clears.
