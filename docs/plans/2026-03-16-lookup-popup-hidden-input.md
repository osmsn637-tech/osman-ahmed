# Lookup Popup Hidden Input Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the shared lookup popup to use a hidden autofocus scanner field and an in-place dark-blue numeric keypad for manual barcode entry.

**Architecture:** Keep `showItemLookupScanDialog()` as the shared entry point and preserve the existing scan normalization and debounce logic. Replace the visible text-entry body with a hidden autofocus `TextField`, a compact scanner status surface, and a conditional manual keypad panel that submits only on confirm.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the new popup behavior with failing tests

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Write the failing test**

Add widget coverage for:
- hidden scan field remaining mounted and focused
- no visible editable lookup field in the popup body
- tapping `Manual Type` reveals the keypad panel
- keypad confirm stays disabled until digits exist
- manual lookup returns only after tapping confirm

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: FAIL because the current popup still exposes a visible text field and has no keypad-confirm flow.

**Step 3: Write minimal implementation**

Update the popup widget to satisfy the new behavior while preserving existing scan submission logic.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: PASS

### Task 2: Implement the hidden-input popup redesign

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`

**Step 1: Replace the visible body input**

- Keep a hidden autofocus `TextField` mounted in the tree
- Preserve scan normalization, debounce, and terminator submission
- Restore focus to the hidden field whenever manual mode closes

**Step 2: Add the manual keypad panel**

- Add a dark-blue `Manual Type` trigger
- Render digits `1-9`, `0`, delete, cancel, and confirm
- Disable confirm until a value exists
- Route confirm through the existing `_searchProduct()` submission path

**Step 3: Refresh supporting UI**

- Show a compact scanner status surface instead of a visible input
- Keep the close action and error text visible
- Use `AppTheme.primary` dark blue accents for manual entry and primary keypad actions

**Step 4: Verify**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart
```

Expected: PASS
