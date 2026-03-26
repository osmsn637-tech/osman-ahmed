# Lookup Location Scan Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add lookup-only scan auto-detection so the shared popup routes item scans to the existing item results page and location scans to a new location-items results page backed by `POST /mobile/v1/locations/scan`.

**Architecture:** Reuse the existing shared scan dialog widget with a new auto-detect mode that returns a structured result, keep `Adjust` on the current item-only wrapper, and add a small move-feature location lookup stack spanning endpoint, parser, use case, controller, route, and result page.

**Tech Stack:** Flutter, Provider, GoRouter, Dio `ApiClient`, existing move feature repositories/controllers/pages, Flutter widget tests.

---

### Task 1: Add failing popup tests for auto-detect lookup mode

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

Add focused tests that expect:
- lookup auto-detect mode returns `location` when manual input is `A10.2`
- lookup auto-detect mode still returns `item` when manual input is `123456`
- item-only wrapper still returns a plain string for existing callers

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

Expected: FAIL because the popup does not yet expose a structured lookup result.

**Step 3: Write minimal implementation**

Add structured scan result types and a lookup auto-detect dialog helper while
preserving the existing item-only helper.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

Expected: PASS

### Task 2: Add failing data-source test for location scan API

**Files:**
- Modify: `test/features/move/data/datasources/item_remote_data_source_test.dart`

**Step 1: Write the failing test**

Add a test expecting `POST /mobile/v1/locations/scan` with `{ "barcode": ... }`
and a parsed location result containing item rows.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart`

Expected: FAIL because the endpoint and parser do not exist.

**Step 3: Write minimal implementation**

Add endpoint, entity/model, repository/data-source method, and use case for
location scan lookup.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/data/datasources/item_remote_data_source_test.dart`

Expected: PASS

### Task 3: Add failing flow test for lookup routing to location results

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Create: `test/features/move/presentation/pages/location_lookup_result_page_test.dart`

**Step 1: Write the failing test**

Add coverage that lookup entry routing can open a location results page and that
the page renders location code, item count, and location item rows.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart`

Expected: FAIL because the route/page/controller do not exist.

**Step 3: Write minimal implementation**

Add the location lookup controller, page, route, provider wiring, and worker
home/more-page lookup routing changes.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart`

Expected: PASS

### Task 4: Run focused regression checks

**Files:**
- Modify only if regressions appear

**Step 1: Run focused regression tests**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart test/features/move/data/datasources/item_remote_data_source_test.dart test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart
```

Expected: PASS

**Step 2: Run broader move-feature confidence checks**

Run:

```bash
flutter test test/features/move
```

Expected: PASS
