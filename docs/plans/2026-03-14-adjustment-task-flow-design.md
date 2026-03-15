# Adjustment Task Flow Design

**Date:** 2026-03-14

## Goal

Replace the current lookup-based adjust flow with a real dashboard adjustment-task flow that matches the mobile adjustment API and supports explicit increase/decrease quantity changes.

## Current Problem

The existing worker `Adjust` action reuses the item lookup result page and sends a generic stock-adjustment request with `new_quantity`. That does not match the provided mobile adjustment API, which is task-based:

- `GET /mobile/v1/adjustments/my-tasks`
- `POST /mobile/v1/adjustments/:adjustmentId/scan-location`
- `POST /mobile/v1/adjustment-items/:id/count`

It also treats the entered quantity as a replacement quantity instead of a delta, which makes a deduction such as `10 - 3` incorrectly become `3`.

## Decision

Move adjustment work into the worker task flow.

- Adjustment becomes a first-class dashboard task type.
- Adjustment execution lives in `WorkerTaskDetailsPage`, not the lookup result page.
- The worker scans a task location, sees expected products for that location, then adjusts one product at a time.
- The UI requires an explicit `Increase` or `Decrease` mode.
- The worker enters a delta quantity, and the app computes `actualQuantity` locally before submit.

## User Flow

1. Worker opens an `Adjustment` task from the dashboard.
2. Task details page shows task header and prompts for location scan.
3. App calls `POST /mobile/v1/adjustments/:adjustmentId/scan-location`.
4. API returns the scanned location and expected products, including current system quantity and counted state.
5. Worker selects a product.
6. Worker chooses `Increase` or `Decrease`.
7. Worker enters a delta quantity and optional note.
8. UI shows:
   - current quantity
   - change amount
   - new quantity
9. App submits `actualQuantity` to `POST /mobile/v1/adjustment-items/:id/count`.
10. Successful submit marks the item as counted locally and updates the displayed quantity.

## API Mapping

### Task list

Dashboard tasks continue to come from `GET /mobile/v1/adjustments/my-tasks`, parsed into `TaskEntity` with `TaskType.adjustment`.

### Scan location

`POST /mobile/v1/adjustments/:adjustmentId/scan-location`

Request:

```json
{
  "barcode": "string"
}
```

Response shape used by the app:

```json
{
  "locationId": "string",
  "locationCode": "string",
  "products": [
    {
      "itemId": "string",
      "productId": "string",
      "productName": "string",
      "productImage": "string",
      "systemQuantity": 12,
      "batchNumber": "string",
      "expiryDate": "string",
      "counted": false
    }
  ]
}
```

The implementation must preserve the item identifier required for submit. If the real payload exposes a dedicated adjustment-item id field, the app should use that exact field instead of inventing a new one.

### Submit count

`POST /mobile/v1/adjustment-items/:id/count`

Request:

```json
{
  "actualQuantity": 7,
  "notes": "string"
}
```

## Quantity Rules

- Entered quantity is always a delta.
- `Increase` means `actualQuantity = systemQuantity + delta`.
- `Decrease` means `actualQuantity = systemQuantity - delta`.
- Delta must be greater than zero.
- Decrease cannot produce a negative final quantity.

## UI State

The adjustment task detail flow needs:

- scanned location code
- loading/error state for location scan
- scanned product list
- selected product
- operation mode: `increase` or `decrease`
- delta quantity
- preview quantity
- submit loading/error/success state

Each product row should visibly show whether it is already counted.

## Error Handling

- Invalid location scan keeps the worker on the scan step with an inline error.
- Failed submit keeps selected product, mode, delta, and note intact.
- Successful submit updates the selected row locally without requiring a page reload.

## Test Coverage

- datasource/repository tests for scan-location parsing and submit payload mapping
- controller tests for increase/decrease math and no-negative guard
- widget tests for adjustment task details flow
- regression coverage that lookup mode no longer acts as the production adjustment path
