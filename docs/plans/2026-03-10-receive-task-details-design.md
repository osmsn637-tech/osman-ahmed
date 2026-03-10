# Receive Task Details Redesign Design

**Date:** 2026-03-10

## Goal

Redesign the worker task details experience for `receive` tasks into a strict 2-page flow: first validate the item barcode from `Inbound`, then unlock a second page for bulk-location validation and task completion.

## Scope

This redesign applies only to `receive` tasks in the worker task details screen.

Out of scope:
- Task cards on the worker home list
- Other task types such as move, return, refill, adjustment, exception, and cycle count
- Backend API changes

## Problem

The current receive details flow is still too compressed and does not separate the worker's two physical actions clearly enough. Workers need a hard split between item validation and bulk-location validation:

- Source is always `Inbound`
- The item barcode now comes from the API response field `product_barcode`
- The worker must finish barcode validation before the bulk step is available
- The item image should be smaller and fully visible instead of heavily cropped
- Completion must stay unavailable until the bulk location is validated on the second page

## User Flow

1. Worker opens a `receive` task from the task list, or starts it.
2. The details page opens on Page 1 only.
3. Page 1 shows:
   - smaller item image
   - item name
   - barcode from `product_barcode`
   - quantity
   - `From Inbound`
4. The worker scans and validates the item barcode on Page 1.
5. If the barcode matches, the UI automatically opens Page 2.
7. Page 2 shows the destination bulk location and asks the worker to scan it.
8. If the bulk location matches, the task becomes completable.
9. The worker presses complete on Page 2.

## Layout

### Header

Keep the app bar and status treatment simple. Do not add extra generic task metadata for receive tasks.

### Page 1

Page 1 contains only:
- a lookup-result-style blue hero card
- centered item image
- centered item name
- centered blue barcode pill
- quantity stat card
- `From Inbound`
- barcode input and validate action

This page should stay compact enough that the worker can see the image and barcode without excessive scrolling.

### Page 2

Page 2 contains only:
- bulk destination location
- location input
- validate bulk location action
- complete action

Page 2 is locked until Page 1 has a successful barcode validation.

## Behavior Rules

- Only `receive` tasks use this receive-specific layout.
- `Inbound` is a literal label, not a warehouse code.
- The displayed and validated receive barcode must come from `product_barcode` when the API provides it.
- The destination location comes from `task.toLocation`.
- Page 2 must stay locked until the barcode on Page 1 is validated.
- A successful barcode validation should automatically transition the user to Page 2.
- If the user edits the barcode input after validating it, Page 2 relocks.
- Completion must not be available before the bulk location is validated on Page 2.
- Existing behavior for non-receive tasks remains unchanged.

## Copy Direction

The wording should stay direct and operational:
- `From Inbound`
- `Page 1`
- `Validate barcode`
- `Page 2`
- `Bulk location`
- `Validate bulk location`

The flow should make it obvious that the second page is not available until the first physical check is complete.

## Testing Intent

The redesign should be covered with receive-specific tests that verify:
- API barcode mapping prefers `product_barcode`
- Page 1 renders a lookup-result-style hero card, API barcode, and `Inbound`
- Page 2 stays locked before barcode validation
- Page 2 opens automatically after barcode validation
- complete action remains disabled until bulk location validation passes
- non-receive tasks keep the current layout
