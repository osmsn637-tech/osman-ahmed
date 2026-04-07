# Ground Location Type Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make lookup and adjust support `GRND` as a third location type named `ground`, separate from shelf and bulk.

**Architecture:** Update the shared location-code helpers and move-layer parsing so `ground` becomes a first-class type instead of being folded into `bulk`. Then extend the move summary/entity/UI layer to expose and render three location groups, and update the adjust controller’s manual code inference to recognize typed `GRND` locations.

**Tech Stack:** Flutter, Dart, flutter_test, shared move entities/controllers/pages.

---

### Task 1: Add failing parsing and controller tests

**Files:**
- Modify: `test/features/move/data/models/item_location_summary_model_test.dart`
- Modify: `test/features/move/presentation/controllers/item_adjustment_controller_test.dart`

**Step 1: Write the failing model regression**
- Change the existing `GRND` inference expectation from `bulk` to `ground`.
- Assert the parsed entity exposes the location under a new `groundLocations` bucket.

**Step 2: Run the focused model test**
- Run: `flutter test test/features/move/data/models/item_location_summary_model_test.dart`
- Expected: FAIL because `GRND` still parses as `bulk`.

**Step 3: Write the failing controller regression**
- Add a test showing typed `GRND` location codes mark the selected location type as `ground`.

**Step 4: Run the focused controller test**
- Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`
- Expected: FAIL because manual inference still returns `bulk` for `GRND`.

### Task 2: Add a failing lookup page regression for the third section

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Add a lookup/adjust widget test**
- Build a fake repository that returns shelf, bulk, and ground locations.
- Verify the page renders `Ground Locations` and includes the ground row in total locations.

**Step 2: Run the focused lookup page test**
- Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --plain-name "lookup mode renders ground locations in a separate section"`
- Expected: FAIL because the page still has only shelf and bulk sections.

### Task 3: Implement ground as a first-class move location type

**Files:**
- Modify: `lib/shared/utils/location_codes.dart`
- Modify: `lib/features/move/data/models/item_location_model.dart`
- Modify: `lib/features/move/domain/entities/item_location_entity.dart`
- Modify: `lib/features/move/domain/entities/item_location_summary_entity.dart`
- Modify: `lib/features/move/presentation/controllers/item_adjustment_controller.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- Modify: `lib/shared/ui/location_row.dart`
- Modify: `lib/features/dashboard/presentation/shared/location_format.dart`

**Step 1: Split bulk and ground detection**
- Add a dedicated ground detector.
- Stop treating `GRND` as bulk in the shared helpers.
- Keep recognized-location validation accepting all three types.

**Step 2: Extend move entities and parsing**
- Parse `GRND` as `ground`.
- Add `isGround` and `groundLocations` helpers.

**Step 3: Update adjust inference**
- Make typed `GRND` location codes resolve as `ground`.

**Step 4: Update lookup/adjust UI**
- Count shelf, bulk, and ground locations in the summary card.
- Render a Ground Locations section with its own label and badge color.
- Update location input hints to mention ground along with shelf and bulk.

**Step 5: Keep shared location formatting consistent**
- Make dashboard location-type formatting recognize ground too, so the shared location-code split does not create unknown labels elsewhere.

### Task 4: Verify the move flow

**Files:**
- Modify as needed from tasks above

**Step 1: Run focused move tests**
- `flutter test test/features/move/data/models/item_location_summary_model_test.dart`
- `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart`
- `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 2: Run analyzer on touched files**
- `dart analyze lib/shared/utils/location_codes.dart lib/features/move/data/models/item_location_model.dart lib/features/move/domain/entities/item_location_entity.dart lib/features/move/domain/entities/item_location_summary_entity.dart lib/features/move/presentation/controllers/item_adjustment_controller.dart lib/features/move/presentation/pages/item_lookup_result_page.dart lib/shared/ui/location_row.dart lib/features/dashboard/presentation/shared/location_format.dart test/features/move/data/models/item_location_summary_model_test.dart test/features/move/presentation/controllers/item_adjustment_controller_test.dart test/features/move/presentation/pages/item_lookup_flow_test.dart`
