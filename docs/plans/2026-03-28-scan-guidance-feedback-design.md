# Scan Guidance and Feedback Design

**Date:** 2026-03-28

## Goal

Make scanner-heavy warehouse flows easier to follow by showing the user one clear next step at a time and by making successful and failed scans feel more obvious.

## Decision

Keep the first pass inside the two highest-value flows:

- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`

Reuse the state that already exists in each page instead of introducing a shared scan framework. Add a reusable visual treatment for `Next step` guidance and stronger scan-result feedback, while keeping current repositories, controllers, and navigation behavior unchanged.

## Scope

In scope:

- worker task execution guidance for receive, refill, return, and cycle count
- inbound receipt guidance for list and detail states
- stronger positive and negative inline feedback for scan outcomes
- inbound success/failure haptic and system-sound feedback
- widget tests covering the new visible guidance and feedback states

Out of scope:

- lookup and adjustment pages
- backend or repository contract changes
- custom audio assets
- a cross-app scan-feedback service

## UX Rules

1. Each active scanner-heavy screen should show a prominent `Next step` card near the current action area.
2. The card should describe the immediate action only, such as scan item, scan location, enter quantity, or confirm quantity.
3. The guidance should update as soon as state changes unlock the next step.
4. Scan success should feel visually stronger than the current passive message treatment.
5. Scan failure should keep clear corrective language and remain visually obvious without trapping the user in a dead end.

## Worker Task Behavior

For `WorkerTaskDetailsPage`, the page already tracks enough state to drive guidance:

- receive/refill: `_receivePage`, `_refillPage`, `_itemValidated`, `_locationValidated`
- return: `_returnPage` and per-line validation state
- cycle count: `_cycleCountPage`, `_selectedCycleCountItem`, `_locationValidated`

The page should render a `Next step` panel above the active scan/input area that reflects the current workflow stage. Examples:

- receive/refill page 0: scan the correct product
- receive/refill page 1: scan the destination location
- return page 0: scan the tote or first item
- return page 1: validate each return line location and quantity
- cycle count list page: scan the count location
- cycle count detail page: scan the item barcode, then enter the counted quantity

Existing validation alerts should stay inline, but their visual treatment should become a little bolder so success and failure are easier to distinguish at a glance.

## Inbound Receipt Behavior

For `InboundReceiptPage`, the page and controller already expose enough state to drive guidance:

- `canReceiveItems`
- `selectedItem`
- `detailOpenedByScan`
- `isQuantityEnabled`
- `scanErrorMessage`

The receipt list page should show guidance like:

- before start: start receiving to unlock item scanning
- active receipt list: scan an item barcode or type it manually

The detail page should show guidance like:

- tapped into detail: scan this line's barcode to unlock quantity
- scanned into detail: enter the received quantity and expiration date
- when quantity is ready: confirm the received quantity

Inbound should also gain scan-result feedback parity with the task page by playing success/failure feedback on completed barcode validations.

## Error Handling

- Existing mismatch/error messages remain the source of truth.
- The new guidance card should not duplicate raw backend errors.
- Failure feedback should guide correction, not just say something went wrong.
- If a page is blocked by workflow state, the guidance should explain the blocker instead of implying the scanner is broken.

## Testing Intent

Widget coverage should prove:

- worker task pages show the correct next-step message as the receive flow advances
- worker task mismatch/success feedback stays visible with the stronger treatment
- inbound receipt list shows guidance before and after starting receipt processing
- inbound receipt detail guidance changes between tap-open and scan-open states
- inbound mismatch feedback stays visible and confirmation guidance appears when quantity entry is unlocked
