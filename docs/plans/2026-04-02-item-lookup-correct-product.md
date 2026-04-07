# Item Lookup Correct Product Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Switch item lookup adjust submissions to the `correct-product` API and remove the reason requirement while keeping the UI single-location.

**Architecture:** Keep the current page and controller flow intact, but simplify adjustment state so it only validates location plus quantity. Replace the remote request body with the new `product_id` plus `corrections[]` contract and update tests first.

**Tech Stack:** Flutter, Provider, Dio, Flutter test

---

### Task 1: Lock the new API contract in tests

**Files:**
- Modify: `test/features/move/data/datasources/item_remote_data_source_test.dart`
- Modify: `test/features/move/presentation/controllers/item_adjustment_controller_test.dart`
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing test**

- Change datasource expectations from `/mobile/v1/adjustments/quick` to `/mobile/v1/adjustments/correct-product`.
- Remove `reason` expectations.
- Assert `product_id` and `corrections: [{ location_barcode, actual_quantity }]`.
- Change controller and widget tests so confirm depends only on valid location plus quantity.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart --reporter expanded`

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart --reporter expanded`

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --reporter expanded`

Expected: failures showing old endpoint, old payload, and old reason-gated UI assumptions.

### Task 2: Update domain and data mapping

**Files:**
- Modify: `lib/features/move/domain/entities/stock_adjustment_params.dart`
- Modify: `lib/features/move/data/datasources/item_remote_data_source.dart`

**Step 1: Write minimal implementation**

- Remove `reason` from `StockAdjustmentParams`.
- Post to `AppEndpoints.correctProductAdjustment`.
- Send `product_id` as a numeric value.
- Send `corrections` with one entry built from the selected location barcode and actual quantity.
- Omit `notes` unless present.

**Step 2: Run tests**

Run: `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart --reporter expanded`

Expected: PASS

### Task 3: Simplify controller and adjust UI gating

**Files:**
- Modify: `lib/features/move/presentation/controllers/item_adjustment_controller.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`

**Step 1: Write minimal implementation**

- Remove selected-reason state and related helper methods/constants.
- Change `canSubmit` to require only valid location plus quantity and not submitting.
- Build `StockAdjustmentParams` without reason.
- Remove reason chips from the adjust panel.
- Keep the submit lock and error handling intact.

**Step 2: Run tests**

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart --reporter expanded`

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --reporter expanded`

Expected: PASS

### Task 4: Update training/demo references

**Files:**
- Modify: `lib/training/main_adjust_training.dart`

**Step 1: Write minimal implementation**

- Remove the scripted reason-selection step.
- Renumber the banner text so the training flow still reads correctly.

**Step 2: Run focused verification**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --reporter expanded`

Expected: PASS with no compile errors from removed reason references.

### Task 5: Final verification and formatting

**Files:**
- Modify: touched files above

**Step 1: Format**

Run: `dart format lib/features/move/domain/entities/stock_adjustment_params.dart lib/features/move/data/datasources/item_remote_data_source.dart lib/features/move/presentation/controllers/item_adjustment_controller.dart lib/features/move/presentation/pages/item_lookup_result_page.dart lib/training/main_adjust_training.dart test/features/move/data/datasources/item_remote_data_source_test.dart test/features/move/presentation/controllers/item_adjustment_controller_test.dart test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 2: Verify**

Run: `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart --reporter expanded`

Run: `flutter test test/features/move/presentation/controllers/item_adjustment_controller_test.dart --reporter expanded`

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --reporter expanded`

Expected: all pass
