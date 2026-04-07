# Item Lookup Quick Adjust Design

## Goal

Update the item lookup `Adjust Item` flow to use the new quick-adjust mobile route and simplify the UI so the worker adjusts by choosing a reason instead of entering a quantity.

## Chosen Approach

Reuse the existing location-selection flow, but replace the quantity input with a required reason picker:

- Keep location selection and manual location-code entry as they work today.
- Replace the quantity field with a required reason selector.
- Submit through `POST /mobile/v1/adjustments/quick`.
- Populate `systemQuantity` from the selected location's current quantity.
- Use the selected location quantity as the fallback `actualQuantity` so the route can be called without a manual quantity field.
- Omit `warehouseId`, `batchNumber`, `expiryDate`, and `notes` unless later data wiring becomes available.

## Why This Approach

- It matches the user's request for a reason-only adjust UI.
- It preserves the existing location targeting behavior workers already know.
- It uses data the lookup result already provides, avoiding a second fetch or hidden quantity logic.

## Assumptions

- The quick-adjust route accepts requests without `warehouseId`.
- The backend allows quick adjustments where `actualQuantity` matches the selected location quantity and the discrepancy is represented by the chosen reason.
- A fixed app-defined reason list is acceptable because the swagger does not provide a reason catalog endpoint.

## Verification

- Add widget tests for the reason-only adjust UI and enabled confirm behavior.
- Add datasource coverage for the new quick-adjust endpoint payload.
- Run targeted move-feature widget/data tests plus analyzer on touched files.
