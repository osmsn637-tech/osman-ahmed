# Lookup Popup Keypad Takeover Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the manual keypad take over the lookup popup by hiding scan-mode sections while manual entry is active.

**Architecture:** Reuse the current scan-first popup and keypad flow. Gate the scan-status panel, manual-entry trigger, and bottom cancel action on the keypad-open state so only the keypad content remains visible in manual mode.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the manual-mode visibility change with a failing test

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

**Step 1: Write the failing test**

Add widget coverage that opens the keypad and expects:
- scan waiting/status copy hidden
- `Manual Type` button hidden
- bottom cancel button hidden

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: FAIL because those scan-mode sections still render during keypad mode.

**Step 3: Write minimal implementation**

Conditionally hide the scan-mode sections while `_manualKeypadOpen` is true.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded`
Expected: PASS

### Task 2: Verify the shared popup entry point

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- Test: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Implement the keypad takeover**

- Hide the waiting/scan panel in manual mode
- Hide the `Manual Type` trigger in manual mode
- Hide the bottom cancel button in manual mode

**Step 2: Verify**

Run:

```bash
flutter test test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart --reporter expanded
flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart --reporter expanded
```

Expected: PASS
