# Item Lookup Correct Product Design

**Date:** 2026-04-02

## Goal

Change item lookup adjust submissions to use the `correct-product` API contract while keeping the current screen as a single-location adjustment flow.

## Scope

- Keep the existing adjust UI centered on one selected location and one entered quantity.
- Remove the adjustment reason requirement from state, validation, and widgets.
- Submit to `POST /mobile/v1/adjustments/correct-product`.
- Map the current single selected location into one item inside `corrections[]`.

## Request Shape

```json
{
  "product_id": 12345,
  "corrections": [
    {
      "location_barcode": "Z01-A03-SS-L04-P06",
      "actual_quantity": 8
    }
  ]
}
```

If notes are provided in the future, the client may include:

```json
{
  "notes": "relocated items"
}
```

## UI Behavior

- Confirm remains disabled until the user has:
  - selected or typed a valid existing location
  - entered a quantity
- The reason chip section is removed entirely.
- The in-flight submission lock remains in place.
- Existing success and error behavior stays unchanged.

## Risks

- Training/demo flows currently script the old reason step and must be updated.
- Tests currently assert the old endpoint and payload and must be rewritten first.
