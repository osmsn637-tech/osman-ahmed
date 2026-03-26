# Adjust Success Popup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a success popup to the standalone item lookup adjust flow and defer navigation until the worker confirms it.

**Architecture:** Keep adjustment success state in the existing controller and handle the popup entirely in the page layer. Replace the current immediate post-success navigation with a one-time dialog, then reuse the existing pop-or-home navigation path after confirm.

**Tech Stack:** Flutter, Provider, GoRouter, flutter_test

---

### Task 1: Lock the new behavior with a widget test

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`

**Step 1: Write the failing test**

Add a widget test that:
- opens item lookup result page in adjust mode
- submits a successful adjustment
- expects a success dialog to be visible
- expects the page not to navigate away before confirm
- taps confirm and expects the existing home navigation

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --plain-name "adjust mode success shows popup before navigating home"`

Expected: FAIL because success currently navigates immediately instead of showing a dialog.

**Step 3: Write minimal implementation**

Update the item lookup result page to:
- detect success once
- show a success `AlertDialog`
- navigate only after confirm

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart --plain-name "adjust mode success shows popup before navigating home"`

Expected: PASS

### Task 2: Verify the full targeted test file stays green

**Files:**
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`

**Step 1: Run the full targeted widget test file**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`

Expected: PASS with no regressions in existing lookup and adjust coverage.
