# Worker Task Scan Feedback Design

**Date:** 2026-03-16

## Goal

Make task-page scanner input stay ready more reliably, give immediate sound feedback on every completed scan, and clear failed scan values after 2 seconds so wrong barcodes do not remain in the input.

## Decision

Keep the change inside `WorkerTaskDetailsPage` and reuse Flutter's built-in feedback APIs. Hidden scan fields will explicitly support autofocus, the active scan field will keep reclaiming focus after scan handling, and failed scan values will be cleared on a short timer.

## Scope

In scope:
- hidden task-page scan fields for product, location, and return barcode capture
- success and failure scan sounds
- delayed clear behavior after failed scans

Out of scope:
- custom audio assets
- non-task-page scanners
- controller or repository changes

## Behavior Rule

1. The active hidden scan field should be able to autofocus when its section is visible.
2. Every completed validation scan plays feedback: success uses the existing click-style feedback pattern and failure uses the existing alert-style feedback pattern.
3. A failed product or location scan keeps its mismatch message visible but clears the raw input value after 2 seconds.
4. Successful scans keep the existing validation and page-flow behavior.

## Testing Intent

- Verify the hidden product scan field is autofocus-capable.
- Verify a failed product scan shows the mismatch state and clears the raw field value after 2 seconds.
- Verify the existing successful validation path still keeps the field scanner-friendly.
