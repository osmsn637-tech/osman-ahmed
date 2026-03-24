# Lookup Popup Dark Blue Grid Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restyle the shared lookup popup into a dark-blue card and fix the manual keypad into a true three-column grid.

**Architecture:** Reuse the current hidden scanner-input and manual-confirm behavior. Update the dialog shell colors and replace the wrapping keypad buttons with a fixed grid layout that remains stable across widths.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the visual/layout regression with failing tests

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

Add widget coverage for:
- the lookup dialog card using `AppTheme.primary`
- the digit keypad using a stable 3-column layout
- confirm-based manual submission still working

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: FAIL because the current card is light and the keypad digits wrap based on available width.

**Step 3: Write minimal implementation**

Update the dialog styling and keypad layout to satisfy the new dark-blue card and three-column grid requirements.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: PASS

### Task 2: Verify the shared entry point regression

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Apply the dark-blue restyle**

- Key the dialog card for testability
- Shift card, status surface, and keypad panel colors into the blue palette
- Keep text/icon contrast accessible

**Step 2: Replace wrap-based keypad layout**

- Use a fixed 3-column widget layout for digits `1-9`
- Keep `Del`, `0`, and `Confirm` in the final row
- Preserve confirm-only manual submission

**Step 3: Verify**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart --reporter expanded
```

Expected: PASS
