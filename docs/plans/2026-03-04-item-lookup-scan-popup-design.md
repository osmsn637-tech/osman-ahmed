# Item Lookup Scan Popup Design

**Date:** 2026-03-04

## Goal
When a user chooses Item Lookup, immediately open a scan popup asking for barcode. After scan, navigate to a separate page that shows item name, item image, and quantity per location.

## UX Flow
1. User enters Item Lookup feature.
2. App opens a modal popup with barcode field and prompt: "Scan barcode".
3. On valid scan submit, close popup and navigate to results page.
4. Results page loads item data using scanned barcode.
5. Page displays item card (name, barcode, image, total quantity) and location rows grouped by shelf/bulk.

## Architecture
- Keep barcode lookup logic in `ItemLookupController`.
- Convert `ItemLookupPage` into an entry page focused on scanner popup and navigation.
- Add a new `ItemLookupResultPage` presentation page for result rendering.
- Add a dedicated route carrying barcode as path parameter.

## Validation and Errors
- Empty barcode in popup: inline validation and keep dialog open.
- Lookup errors handled in results page using existing controller states (`notFound`, `retryable`, etc.).

## Testing Scope
- Popup appears when Item Lookup opens.
- Successful scan navigates to separate results page.
- Result page renders item, image container, and location quantities.
