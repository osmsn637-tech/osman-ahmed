# Adjustment Decrease Stepper Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the adjustment page's `-` button work for decreases without changing the backend payload shape.

**Architecture:** Reuse the existing positive `_adjustmentDelta` state. Update the editor button enablement and delta handlers so the buttons act relative to `_adjustmentMode`, then verify the behavior through the existing adjustment widget test.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Write the failing UI expectation

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Update the adjustment widget test**

- In decrease mode, tap `adjustment-delta-decrement` three times instead of `adjustment-delta-increment`.
- Keep the existing preview and submitted quantity assertions.

**Step 2: Run the focused test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because the `-` button is disabled at zero in decrease mode.

### Task 2: Update the stepper logic

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Make the buttons mode-aware**

- Compute button enablement based on the selected mode.
- In decrease mode, pressing `-` should increase `_adjustmentDelta`.
- In increase mode, pressing `+` should increase `_adjustmentDelta`.
- The opposite button should reduce `_adjustmentDelta` toward zero.

**Step 2: Re-run the focused test**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS for the adjustment flow expectation.
