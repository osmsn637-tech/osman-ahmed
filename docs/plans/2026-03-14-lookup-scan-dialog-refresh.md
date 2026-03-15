# Lookup Scan Dialog Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refresh the shared lookup scan dialog into a compact centered scanner-first popup without footer buttons or auto-opening the keyboard in manual mode.

**Architecture:** Keep the existing shared dialog entry point and scanner/manual logic, but use a smaller custom `Dialog` composition. The new layout removes the bottom action row and changes manual mode so the keyboard opens only when the user taps the field.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the refreshed dialog structure with tests

**Files:**
- Create: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

Add a widget test that opens `showItemLookupScanDialog()` and expects:

- the dialog title
- a manual entry text action
- no footer `Cancel` button
- no footer `Continue` button

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: FAIL because the current dialog uses the older layout.

**Step 3: Write minimal implementation**

Update the dialog UI to satisfy the new structure without changing scanner logic.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`
Expected: PASS

### Task 2: Implement the new dialog shell

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`

**Step 1: Replace the stock shell**

- Use a custom `Dialog`
- Add rounded shape, softer surface, and tighter padding
- Introduce a smaller icon badge and compact title row

**Step 2: Re-layout actions**

- Keep manual entry in the content area
- Remove the bottom action row
- Preserve clear/search affordances inside the field

**Step 3: Keep behavior unchanged**

- Keep scanner focus behavior
- Update manual keyboard enable path so it does not auto-open
- Keep submit/close/clear logic

**Step 4: Verify**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart
```

Expected: PASS
