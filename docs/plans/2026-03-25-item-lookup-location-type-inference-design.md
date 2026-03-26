# Item Lookup Location Type Inference Design

**Date:** 2026-03-25

## Goal

Ensure item lookup shows locations returned by the mobile barcode API when the
location code uses `SB` for shelf storage or `GRND` for ground storage.

## Decision

Keep the current Shelf Locations and Bulk Locations sections, and expand the
location type inference so untyped API rows with `SB` map to shelf and `GRND`
map to bulk.

## Data Handling

- Continue reading location rows from the existing `locations` payload.
- Infer `shelf` when `location_code` contains `-SB-`.
- Infer `bulk` when `location_code` contains `-GRND-`.
- Leave the existing `-SS-` and `-BLK-` rules intact.

## UI Impact

- No layout change is needed on the lookup result page.
- Once the parser assigns the correct type, the existing shelf and bulk
  sections render these rows automatically.

## Testing

- Add a regression test for `ItemLocationSummaryModel` covering API rows with
  `SB` and `GRND` location codes.
- Run the focused model test, then the lookup page flow test to confirm the
  existing UI stays healthy.
