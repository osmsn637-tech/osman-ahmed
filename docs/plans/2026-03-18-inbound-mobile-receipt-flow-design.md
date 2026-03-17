# Inbound Mobile Receipt Flow Design

**Date:** 2026-03-18

## Summary

Replace the current inbound `Receive` shortcut that jumps into the old `/receive` page with a dedicated inbound mobile receipt flow built on `/mobile/v1/inbound/*`.

The new flow should mirror the cycle count interaction model:

1. Scan PO/receipt from inbound home.
2. Open a receipt page that shows receipt summary, receipt items, progress, and a visible `Start receiving` button.
3. After starting, scan an item barcode or tap an item row to open a second page for that item.
4. Confirm or flag the item from the detail page.
5. Return to the receipt page and continue until finish.

## Goals

- Make inbound receiving receipt-driven instead of using the old generic receive page.
- Match the cycle count two-page UX pattern so scanning a receipt opens a list page and scanning an item opens a detail page.
- Use the new `/mobile/v1/inbound/*` endpoints exclusively for the inbound app flow.
- Keep the existing inbound lookup action unchanged.

## Non-Goals

- No use of dashboard receipt create/update endpoints.
- No use of Odoo sync endpoints or PO creation endpoints.
- No migration of inbound receipt flow into worker task infrastructure.
- No backend API redesign beyond client integration.

## Current State

Inbound home currently exposes a `Receive` button that opens the shared scan dialog and then navigates to `/receive?barcode=...`.

That route renders the old [receive_page.dart](/C:/Users/Osman/Desktop/putaway%20app/lib/features/receive/presentation/pages/receive_page.dart), which is item-location receiving and does not model:

- receipt tasks
- receipt start/finish lifecycle
- receipt item lists
- confirm vs flag item actions
- receipt progress counters

The inbound feature also still uses legacy mock entities such as `InboundDocument` and `InboundItem`, which do not match the new mobile receipt API contract.

## Recommended Approach

Create a dedicated inbound mobile receipt stack inside the inbound feature and reuse the cycle count interaction pattern, not the old receive page and not the worker task details page.

This keeps the domain aligned with the new inbound endpoints while preserving a familiar scan-driven UX:

- PO scan opens a receipt list page
- item scan opens a receipt item detail page
- detail confirm/flag returns to the list page

## User Flow

1. User lands on inbound home.
2. User taps `Receive`.
3. Shared scan dialog captures the PO/receipt barcode.
4. App calls `POST /mobile/v1/inbound/receipts/scan`.
5. On success, app navigates to a new inbound receipt page.
6. Receipt page shows:
   - receipt summary card
   - receipt item list
   - progress summary
   - `Start receiving` button when the receipt has not started yet
7. User taps `Start receiving`.
8. App calls `POST /mobile/v1/inbound/receipts/{id}/start`.
9. Once started, user scans an item or taps an item row.
10. App calls `POST /mobile/v1/inbound/receipts/{receipt_id}/scan-item` for scans and opens the matching item detail page.
11. Item detail page shows the required fields.
12. User either confirms or flags the item.
13. App refreshes receipt progress and returns to the receipt page.
14. User repeats until done, then taps `Finish receiving`.
15. App calls `POST /mobile/v1/inbound/receipts/{id}/finish` and the receipt moves to `inspecting`.

## Architecture

### Domain

Add inbound-mobile-specific entities that match the new API instead of stretching the current `InboundDocument` model.

Recommended entities:

- `InboundReceiptTaskPage`
- `InboundReceiptSummary`
- `InboundReceiptItemCard`
- `InboundReceiptProgress`
- `StartInboundReceiptParams`
- `ConfirmInboundReceiptItemParams`
- `FlagInboundReceiptItemParams`

### Repository

The inbound repository should expose the receipt flow directly:

- `getMyTasks({cursor, limit})`
- `scanReceipt(barcode)`
- `startReceipt(id, receivedAt)`
- `scanReceiptItem(receiptId, barcode)`
- `confirmReceiptItem(params)`
- `flagReceiptItem(params)`
- `getReceiptProgress(id)`
- `finishReceipt(id)`

### Presentation

Keep inbound home as the role landing page, but change its receive action to navigate into the new receipt flow.

Recommended pages:

- `InboundHomePage`
- `InboundReceiptPage`
- `InboundReceiptItemPage`

The item page can be implemented as internal two-page state inside `InboundReceiptPage` first, mirroring cycle count. That is the simplest and most consistent approach for this codebase.

## Page Design

### Receipt Page

This page should behave like the cycle count list page.

It shows:

- receipt identifier and summary card
- supplier or related summary fields when present
- progress counters (`total`, `received`, `flagged`, `pending`, `percent`)
- scan entry area for item barcodes
- receipt items list with pending/received/flagged state
- `Start receiving` button before activation
- `Finish receiving` button only when valid for the current status

Behavior:

- successful receipt scan opens this page
- receipt does not auto-start
- item scans are blocked until the receipt is started
- tapping a row or scanning a valid item opens item detail

### Item Detail Page

This page should behave like the cycle count detail page.

It shows:

- item identity
- barcode
- expected quantity
- received quantity
- any existing received or flagged state

Required fields for confirm flow:

- `received_quantity`
- `batch_number`
- `expiry_date`
- `manufacture_date`
- `condition`
- `notes`

Required fields for flag flow:

- `condition`
- `good_quantity`
- `bad_quantity`
- `notes`
- `image_url`

Actions:

- `Confirm`
- `Flag issue`
- back action to return to receipt page without changing the current item

After confirm or flag, the app refreshes progress and returns to the receipt page.

## State Rules

- Before `Start receiving`, the receipt page is visible but item scan and item submit actions are disabled.
- `Start receiving` is explicit and visible on the receipt page.
- After start succeeds, item scanning becomes active.
- `scan-item` opens the item detail page only for a valid pending receipt item.
- `confirm` and `flag` both refresh the receipt state and progress after success.
- `finish` stays on the receipt page when the backend rejects the transition.

## Error Handling

Treat these as first-class UX states:

- `UNAUTHORIZED`: session expired or invalid token; prompt for re-login
- `FORBIDDEN`: inbound role mismatch or route not allowed; show access-blocked guidance
- `INVALID_ID`, `INVALID_REQUEST`: keep the user on the current page and show retry guidance
- `ITEM_NOT_FOUND`: keep the user on the receipt page and show that the scanned item is not a pending scannable line
- `INVALID_STATUS_TRANSITION`: keep the user in place and explain that the receipt cannot be started or finished in its current state

Errors should be actionable and should not silently reset page state unless the session is invalid.

## Routing

Inbound home should no longer route its receive action to `/receive`.

Recommended route:

- `/inbound/receipt/:id`

The item detail can stay inside that page as internal state for the first implementation, which matches the cycle count pattern and avoids unnecessary route complexity.

## Data Refresh Strategy

- Receipt scan returns the summary needed to open the receipt page.
- Receipt page should fetch progress when opened or after mutations if the scan response does not already provide all required data.
- After `start`, `confirm`, `flag`, and `finish`, refresh the receipt summary/progress state from the repository so the list page remains authoritative.

## Testing Strategy

Add coverage for:

- inbound home `Receive` scans a PO and routes to the new receipt page
- lookup action on inbound home remains unchanged
- receipt page shows `Start receiving` before the receipt is active
- starting the receipt enables item scanning
- scanning an item opens the item detail page
- tapping an item row opens the same item detail page
- confirming an item returns to the receipt page and updates counters
- flagging an item returns to the receipt page and updates counters
- finish handles invalid status gracefully
- inbound mobile code uses `/mobile/v1/inbound/*` endpoints instead of the old `/mobile/v1/receipts/*` flow

## Risks

- The current inbound feature contains legacy document models that do not match the new API, so partial reuse will create confusion. New receipt-specific models are cleaner.
- If the receipt scan endpoint returns only a summary and not a complete item list, the repository will need a follow-up fetch strategy to hydrate the receipt page.
- Reusing the old `/receive` page would create behavior drift from the required receipt lifecycle, so it should be left out of the inbound role flow.
