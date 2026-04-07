# Item Lookup Quick Adjust Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Switch item lookup adjust to the quick-adjust route and simplify the UI so workers submit by selecting a reason.

**Architecture:** Keep the current item lookup result page and adjustment controller structure, but change the adjustment state from quantity-driven to reason-driven. Rewire the datasource to post the quick-adjust request body using data from the selected location and lookup summary.

**Tech Stack:** Flutter, Provider, existing move feature repository/datasource stack, Flutter widget tests.

---

### Task 1: Add failing tests for the new adjust contract

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Modify: `test/features/move/data/datasources/item_remote_data_source_test.dart`

**Step 1: Update the widget tests**
- Verify adjust mode shows a reason field and no quantity field.
- Verify confirm stays disabled until a location and reason are selected.
- Verify submission sends the selected reason.

**Step 2: Add datasource coverage for quick-adjust payload**
- Verify the request goes to `/mobile/v1/adjustments/quick`.
- Verify the payload uses `productId`, `locationId`, `systemQuantity`, `actualQuantity`, and `reason`.

**Step 3: Run the focused tests**
- Run the move widget and datasource test files.
- Expected: FAIL before implementation.

### Task 2: Implement the quick-adjust route and reason-only controller state

**Files:**
- Modify: `lib/core/constants/app_endpoints.dart`
- Modify: `lib/features/move/domain/entities/stock_adjustment_params.dart`
- Modify: `lib/features/move/data/datasources/item_remote_data_source.dart`
- Modify: `lib/features/move/presentation/controllers/item_adjustment_controller.dart`

**Step 1: Add the new endpoint constant**
- Define the quick-adjust mobile route in `AppEndpoints`.

**Step 2: Expand the adjustment params**
- Carry the selected location quantity and reason through the request pipeline.

**Step 3: Rewire the datasource**
- Post to the quick-adjust endpoint with the new request body.

**Step 4: Update the controller**
- Remove quantity input state.
- Add required reason selection state.
- Build the quick-adjust params from the selected location and summary.

### Task 3: Replace the adjust panel UI with a reason selector

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`

**Step 1: Replace the quantity field**
- Remove the quantity text input.
- Add a reason picker using app-localized labels.

**Step 2: Keep the location flow intact**
- Preserve tap-to-select location rows and manual location code editing.

**Step 3: Preserve success and error states**
- Keep the existing success popup and inline error behavior.

### Task 4: Verify the final behavior

**Files:**
- Modify as needed from tasks above

**Step 1: Run focused tests**
- `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
- `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart`

**Step 2: Run analyzer on touched files**
- `flutter analyze lib/core/constants/app_endpoints.dart lib/features/move/domain/entities/stock_adjustment_params.dart lib/features/move/data/datasources/item_remote_data_source.dart lib/features/move/presentation/controllers/item_adjustment_controller.dart lib/features/move/presentation/pages/item_lookup_result_page.dart test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/data/datasources/item_remote_data_source_test.dart`
