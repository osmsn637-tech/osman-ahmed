# Ground Location Type Design

## Goal

Make lookup and adjust treat `GRND` as a real `ground` location type so the app supports three location categories: shelf, bulk, and ground.

## Chosen Approach

Promote `ground` to a first-class type in the shared move-location pipeline:

- detect `GRND` separately from `bulk`
- parse API location rows as `ground`
- expose dedicated `ground` buckets on item-location summaries
- render a third Ground Locations section on the lookup/adjust result page
- allow typed `GRND` location codes in adjust mode to resolve as `ground`

## Why This Approach

- It fixes the type once in the parsing layer instead of patching individual screens.
- It keeps lookup and adjust consistent with each other.
- It avoids continuing to collapse ground locations into bulk, which is the current source of the problem.

## UI Impact

- Item lookup result pages will show three sections when applicable:
  - Shelf Locations
  - Bulk Locations
  - Ground Locations
- Adjust mode will allow users to select or type a ground location just like shelf or bulk.
- Existing shelf and bulk behavior stays unchanged.

## Verification

- Add regression coverage for model parsing so `GRND` maps to `ground`.
- Add controller coverage so typed `GRND` codes resolve as `ground` in adjust mode.
- Add lookup page coverage so ground locations render in their own section and count toward total locations.
