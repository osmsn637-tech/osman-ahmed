# Hidden Task Inputs Design

**Date:** 2026-03-15

## Goal

Hide all visible barcode and location validation inputs across worker task flows, keep scanning active through hidden autofocus fields, add manual entry actions, and normalize task count submissions so API payloads use the final quantity value.

## Scope

This redesign applies to worker task validation and count-entry flows inside `WorkerTaskDetailsPage`.

In scope:
- product barcode validation steps
- location validation steps
- cycle count detail barcode entry
- manual barcode and location entry affordances
- task submission payloads that send counts or quantities

Out of scope:
- worker home task cards
- inbound creation flows
- standalone item lookup dialog behavior outside worker tasks
- backend API contract changes

## Requirements

- Remove visible barcode validation inputs from all worker task flows.
- Remove visible location validation inputs from all worker task flows.
- Keep scanning active through hidden inputs that stay focused whenever the current step expects a scan.
- Replace visible inputs with a `Manual Type` action.
- Barcode manual entry opens a numeric keypad-style `3x3` entry surface.
- Location manual entry opens a normal text-entry surface with the full keyboard.
- Barcode input is numeric only. Alphanumeric barcode entry is invalid.
- Any API path that sends item counts must send the quantity value for all task types.

## Decision

Use shared hidden scan fields inside `WorkerTaskDetailsPage` and task-specific manual dialogs.

- Reuse the existing cycle count hidden-focus pattern instead of keeping duplicated visible `TextField` logic in each task layout.
- Keep task-specific step gating intact, but route scan/manual input through a shared active-input target.
- Normalize outgoing count payloads so task submissions always transmit final quantity values rather than deltas or temporary UI values.

## User Flow

1. Worker opens a task detail page.
2. The current task step activates either the hidden barcode scan field or the hidden location scan field.
3. Hardware scanner input is captured through the hidden active field.
4. The worker can tap `Manual Type` instead of scanning.
5. Barcode steps open a numeric keypad dialog.
6. Location steps open a full-keyboard text-entry dialog.
7. Submitted manual values follow the same validation path as scanner values.
8. Successful validation advances the task flow and moves focus to the next hidden active field.
9. Any task submission that sends counts uses the final quantity value in the API payload.

## Interaction Model

### Hidden scan fields

- Product barcode entry becomes a hidden numeric scan field that stays focused whenever the current step expects a barcode.
- Location entry becomes a hidden scan field that stays focused whenever the current step expects a location.
- Hidden scan fields should clear themselves after each accepted attempt so repeated scans do not concatenate stale text.
- Focus should automatically restore after validation and after step transitions unless the next step uses a different active target.

### Manual entry actions

- Every product-barcode step shows a `Manual Type` action instead of a visible input field.
- Every location-validation step shows a `Manual Type` action instead of a visible input field.
- Barcode manual entry uses digits only and rejects non-digit content immediately.
- Location manual entry uses a normal text-entry dialog and preserves the existing location validation rules.
- Cancelling a manual dialog must not clear validated state or other task progress.

## Task Flow Mapping

- Receive, move, refill, return, adjustment, and cycle count flows continue to use their existing step gating.
- Each step declares which hidden input target is active: `productBarcode` or `location`.
- Product validation compares the scanned or manually typed numeric barcode against the expected task barcode.
- Location validation compares or delegates to the existing location validation callback using the hidden location input or manual dialog result.
- Cycle count keeps its scan-first list behavior and replaces the visible detail barcode field with the new numeric barcode keypad flow.

## API Behavior

- Any submission path that sends an item count or quantity to the API must send the final quantity value.
- Adjustment flow must submit the final counted quantity value rather than a delta-shaped value.
- Existing non-count payload fields such as ids, notes, and location references stay unchanged unless needed to support the quantity fix.

## Error Handling

- Empty scans are ignored.
- Invalid barcode input keeps the worker on the current step and shows the existing mismatch or validation messaging.
- Invalid location input keeps the worker on the current step and keeps completion locked.
- Hidden scan focus should be restored after invalid attempts when the same step remains active.

## Testing Intent

- Widget tests should verify visible barcode and location fields are removed from worker task details.
- Widget tests should verify `Manual Type` actions appear on barcode and location steps.
- Widget tests should verify barcode manual entry is numeric-only and location manual entry uses standard text input.
- Widget tests should verify hidden scanner focus is restored after validation and after task-step transitions.
- Regression tests should cover receive, move, refill, return, adjustment, and cycle-count flow progression.
- Repository or controller tests should verify affected API count payloads send final quantity values.
