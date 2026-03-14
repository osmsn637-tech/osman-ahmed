# Worker Adjust Flow Design

## Summary

Add an `Adjust` action under the existing worker home `Lookup` button. The new action uses the same scan popup as lookup, then opens the same item result page in an adjustment mode instead of creating a separate screen.

The shared result page keeps the existing item identity and location summary UI, but adjustment mode adds a selected-location workflow and an editable adjustment panel. The worker chooses one location, changes quantity with `-` and `+`, chooses a reason such as `Damaged` or `Return`, optionally adds a note, and confirms the stock adjustment for that selected location.

## Goals

- Keep `Lookup` and `Adjust` visually and behaviorally aligned at the scan step.
- Reuse the existing item result page instead of building a second item-details screen.
- Make adjustment location-specific, not total-item-only.
- Keep the adjustment interaction simple enough for scan-first worker use.

## Non-Goals

- No redesign of the standalone `/adjustment` page in this step.
- No change to the existing lookup-only behavior when opened from `Lookup`.
- No multi-location batch adjustment in one confirmation.

## Current State

Worker home currently exposes one top-level `Lookup` button in [worker_home_page.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/dashboard/presentation/pages/worker_home_page.dart). That button opens [item_lookup_scan_dialog.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/move/presentation/pages/item_lookup_scan_dialog.dart) and routes to [item_lookup_result_page.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/move/presentation/pages/item_lookup_result_page.dart).

The lookup result page is read-only. It shows item details and grouped shelf/bulk locations, but it does not support selecting a location or submitting an inventory adjustment.

There is a separate [stock_adjustment_page.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/move/presentation/pages/stock_adjustment_page.dart), but it is a different flow and currently expects raw item and location ids rather than reusing the lookup result experience.

## Proposed Architecture

### Shared Result Page Modes

The existing item result page should support two explicit modes:

- `lookup`: current read-only behavior
- `adjust`: same item lookup data plus adjustment controls

The route can stay on the same page path and pass mode through a query parameter, for example:

- `/item-lookup/result/6287009170024`
- `/item-lookup/result/6287009170024?mode=adjust`

This keeps one route, one lookup controller, and one page component while making the adjustment behavior explicit.

### Worker Home Actions

Worker home should render two full-width buttons in the same section:

- `Lookup`
- `Adjust`

`Adjust` should match the existing `Lookup` button style and sizing, appear directly under it, and call the same scan dialog helper. The only difference is the destination route: the scanned barcode should navigate to the shared result page in `adjust` mode.

### Adjustment State

Adjustment mode should use its own route-local controller instead of reusing the global stock-adjustment page controller.

Reasoning:

- the shared result page needs adjustment state scoped to one scanned item
- it needs selection of a location from lookup results
- it needs quantity stepper behavior, reason choice, optional note, submit loading, and inline errors
- it should not leak mutable state into the standalone stock adjustment screen

Recommended controller responsibilities:

- track selected location id
- track selected location code for UI highlight
- track adjustment quantity
- track selected reason
- track optional note
- validate whether confirm is allowed
- submit the final adjustment through `AdjustStockUseCase`

### Selected Location Workflow

Adjustment mode keeps the existing shelf and bulk sections, but location rows become selectable.

Behavior:

- tapping a row marks it as the active adjustment location
- the selected row gets a stronger visual state
- only one location can be selected at a time
- the adjustment panel uses the selected row's `locationId`

This preserves the current information architecture while making the worker choose the exact location being adjusted.

### Adjustment Panel

In adjustment mode, render one adjustment panel below the location lists.

Controls:

- quantity stepper with only `-` and `+`
- reason selector with predefined options:
  - `Damaged`
  - `Return`
  - `Count Correction`
  - `Cycle Count`
  - `Other`
- optional note text field
- `Confirm` button

Validation:

- quantity starts at `0`
- quantity cannot go below `0`
- a location must be selected before confirm
- quantity must be greater than `0` before confirm
- reason must be selected before confirm
- note is optional

## Data Contract

The existing lookup summary already exposes `itemId` and per-location `locationId`, which is enough to support a selected-location adjustment.

The stock adjustment request should be extended to carry optional note text in addition to the existing required fields:

- `item_id`
- `location_id`
- `new_quantity`
- `reason`
- `worker_id`
- `note` when present

If the backend ignores unknown fields, this is forward-compatible. If the backend expects `note`, this makes the UI capable of supplying it without overloading `reason`.

## Routing and Providers

Recommended routing change:

- keep the existing result route path
- parse a `mode` query parameter in [router_provider.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/shared/providers/router_provider.dart)
- create both the lookup controller and the new route-local adjustment controller for the page

The shared result page should read:

- lookup state from `ItemLookupController`
- page mode from route input
- adjustment state from the new adjustment controller only when mode is `adjust`

## User Flow

1. Worker opens home.
2. Worker taps `Adjust`.
3. Existing scan popup opens.
4. Worker scans item barcode.
5. App navigates to shared result page in `adjust` mode.
6. Page loads item summary and locations.
7. Worker taps one shelf or bulk location.
8. Worker changes quantity with `-` and `+`.
9. Worker chooses reason, optionally enters note, and taps `Confirm`.
10. App submits one stock adjustment for the selected location.
11. On success, show success feedback and return the worker back to the previous page.

## Error Handling

- Lookup failure keeps the existing result-page loading and error states.
- Confirm stays disabled until the minimum valid state is met.
- Submission failure keeps the user on the page and shows an inline retryable error.
- Selected location should remain selected after a failed submit.
- Quantity, reason, and note should remain intact after a failed submit.

## Testing Strategy

Add coverage for:

- worker home shows `Adjust` under `Lookup`
- `Adjust` opens the same scan popup
- adjust navigation opens the shared result page in adjustment mode
- adjustment mode renders selectable locations and the adjustment panel
- selecting a location updates the selected state
- `-` and `+` change quantity and never allow negative values
- reason options include `Damaged` and `Return`
- confirm stays disabled without location selection or positive quantity
- confirm submits the selected location id, scanned item id, reason, and optional note
- lookup mode remains unchanged and read-only

## Risks

- The result page already handles several loading and error states, so mode branching should stay explicit and shallow to avoid turning the page into a large conditional block.
- The existing stock adjustment flow and the new worker adjustment flow will overlap in domain behavior. Shared request models should be reused, but UI state should stay separate.
