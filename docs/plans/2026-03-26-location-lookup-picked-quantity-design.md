# Location Lookup Picked Quantity Design

**Date:** 2026-03-26

## Goal

Show the picked quantity beside the current quantity on each item row in the
location lookup result page.

## Scope

- Applies only to the location lookup result page.
- Uses backend field `picked_quantity`.
- Defaults missing or invalid picked quantity values to `0`.
- Keeps the location header summary unchanged.

## Decision

Use a minimal row-level change:

- extend the location lookup item model/entity with `pickedQuantity`
- parse `picked_quantity` from `/mobile/v1/locations/scan`
- render both `Qty` and `Picked Qty` on each location item row

This keeps the UI stable, matches the backend payload, and avoids changing the
page summary or route flow.

## Architecture

- Update `LocationLookupItemEntity` and `LocationLookupItemModel` to carry
  `pickedQuantity`.
- Extend the location scan parser to read `picked_quantity`, with a fallback of
  `0`.
- Update the row layout in `location_lookup_result_page.dart` so the right side
  shows two compact stat blocks instead of only one quantity block.

## Error Handling

- If `picked_quantity` is missing, null, or malformed, treat it as `0`.
- Existing not-found and retry states remain unchanged.

## Testing

- Data-source parsing test should confirm `picked_quantity` is mapped.
- Widget test should confirm the location result page renders both quantity and
  picked quantity values.
