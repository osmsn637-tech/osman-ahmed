# Lookup Location Scan Design

**Date:** 2026-03-26

## Goal

Extend the shared lookup scan popup so the worker can scan either an item barcode
or a location code from the same popup, auto-detect the scan type for lookup
only, and open a location-items result page when the scan is a location.

## Scope

- Applies only to `Lookup`.
- `Adjust` continues using the same popup in item-only mode.
- Auto-detection uses the app's known location-code patterns.
- A location scan calls `POST /mobile/v1/locations/scan` and shows the items in
  that scanned location.

## Decision

Use a hybrid lookup flow:

- if the scanned value matches known location-code formats, treat it as a
  location scan
- otherwise treat it as an item barcode scan

Known location formats come from the existing location helpers and include:

- compact shelf codes like `A10.2`
- compact bulk codes like `BULK A2.2`
- legacy location codes containing `-SS-`, `-SB-`, `-BLK-`, or `-GRND-`

## Architecture

- Keep the existing shared popup widget and add a lookup auto-detect mode that
  returns a structured scan result instead of always returning a plain barcode.
- Keep `showItemLookupScanDialog` for item-only callers so `Adjust` remains
  unchanged.
- Add a location lookup entity/model/controller/page for scanned locations.
- Add a new move-domain use case and repository/data-source method for
  `POST /mobile/v1/locations/scan`.
- Route location scans to a dedicated location result page.

## API Assumption

The request body for `POST /mobile/v1/locations/scan` will send:

```json
{
  "barcode": "<scanned-location-code>"
}
```

The response parser should be tolerant and accept either `items` or `products`
collections, along with common field aliases for ids, names, barcodes, images,
and quantities.

## UI Behavior

- Lookup popup auto-detect mode accepts both barcode-like and location-like
  manual input.
- Item scans continue to open the current item result page.
- Location scans open a result page with:
  - scanned location code
  - item count
  - total quantity
  - list of items stored in that location

## Error Handling

- Empty scan keeps the popup open with inline validation.
- Location lookup network/server errors show a retryable state on the location
  result page.
- Not found location scans show a dedicated not-found state.

## Testing

- Popup returns a location scan result for recognized location codes.
- Popup keeps item-only behavior for existing callers.
- Remote data source posts to `/mobile/v1/locations/scan` with the expected
  body and parses returned items.
- Worker-home lookup can navigate to the location result page.
- Location result page renders scanned location items and retry/not-found states.
