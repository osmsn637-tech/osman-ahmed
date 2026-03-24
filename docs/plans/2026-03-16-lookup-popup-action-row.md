# Lookup Popup Action Row Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve the lookup popup styling and replace the overflowing keypad action row with label-fitting action pills.

**Architecture:** Reuse the current hidden scanner-input, dark-blue card, and fixed digit grid. Update only the action-row layout and supporting spacing so `Delete` and `Confirm` fit cleanly without truncation or overflow.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the narrow-width regression with a failing test

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

Add widget coverage that:
- opens the keypad on a narrow surface width
- confirms the `Delete` and `Confirm` labels are visible
- confirms no layout exception is produced

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: FAIL because the current action row can overflow its text labels.

**Step 3: Write minimal implementation**

Replace the equal-width action row with a label-fitting layout and adjust spacing/styles as needed.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: PASS

### Task 2: Verify the shared popup entry point

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Implement the action-row polish**

- Keep the 3x3 digit grid unchanged
- Make `Delete`, `0`, and `Confirm` fit their text cleanly
- Preserve confirm-only submission and hidden scanner focus

**Step 2: Verify**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart --reporter expanded
```

Expected: PASS
