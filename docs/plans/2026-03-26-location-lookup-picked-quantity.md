# Location Lookup Picked Quantity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add picked quantity to location lookup results so each scanned
location item shows both available quantity and picked quantity.

**Architecture:** Extend the existing location lookup item entity/model with a
`pickedQuantity` field, parse `picked_quantity` from the backend response, and
update the row UI to render two value blocks on the right side. Keep the page
header and controller flow unchanged.

**Tech Stack:** Flutter, Provider, existing move feature location lookup stack,
Flutter widget tests.

---

### Task 1: Add failing tests for picked quantity parsing and rendering

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\test\features\move\data\datasources\item_remote_data_source_test.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\test\features\move\presentation\pages\location_lookup_result_page_test.dart`

**Step 1: Write the failing test**

Add assertions that:
- `scanLocation` parses `picked_quantity`
- the location result page renders both `Qty` and `Picked Qty`

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/features/move/data/datasources/item_remote_data_source_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart
```

Expected: FAIL because the model/entity/page do not yet support picked
quantity.

**Step 3: Write minimal implementation**

Add `pickedQuantity` to the entity/model and update the location result row UI.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/features/move/data/datasources/item_remote_data_source_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart
```

Expected: PASS

### Task 2: Run targeted regression checks

**Files:**
- Modify only if regressions appear

**Step 1: Run focused tests**

Run:

```bash
flutter test test/features/move/data/datasources/item_remote_data_source_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart
```

Expected: PASS

**Step 2: Run broader move-page confidence checks**

Run:

```bash
flutter test test/features/move
```

Expected: PASS
