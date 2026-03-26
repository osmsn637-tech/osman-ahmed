# Item Lookup Location Type Inference Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make item lookup show API locations whose codes imply shelf or bulk storage without an explicit `type` field.

**Architecture:** Keep the current lookup result UI unchanged and fix the issue in the data-model parsing layer. The parser already infers types from some code segments, so this work only extends that inference to cover `SB` and `GRND`.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Add the regression test for mobile lookup parsing

**Files:**
- Modify: `test/features/move/data/models/item_location_summary_model_test.dart`

**Step 1: Write the failing test**

Add a test that parses a lookup payload with:

- `location_code: Z03-C16-SB-L01-P03`
- `location_code: Z03-PT01-GRND-L01-P01`

Expect the parsed location types to be `shelf` and `bulk`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/data/models/item_location_summary_model_test.dart`
Expected: FAIL because the parser currently returns an empty type for those code segments.

**Step 3: Write minimal implementation**

Extend the code-based type inference to recognize `SB` as shelf and `GRND` as
bulk.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/data/models/item_location_summary_model_test.dart`
Expected: PASS

### Task 2: Confirm lookup UI behavior still works with parsed locations

**Files:**
- Modify: `lib/features/move/data/models/item_location_model.dart`
- Verify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Keep the parser change minimal**

Only extend `_inferTypeFromCode()` and do not change the lookup page layout.

**Step 2: Re-run focused verification**

Run:

```bash
flutter test test/features/move/data/models/item_location_summary_model_test.dart
flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart
```

Expected: PASS
