# Manual Barcode Keypad Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the manual barcode keypad a true 3x3 numeric pad and improve its visual design without changing barcode entry behavior.

**Architecture:** Keep the keypad dialog self-contained inside `WorkerTaskDetailsPage`, but replace the responsive `Wrap` layout with a fixed grid and a dedicated action row. Lock the new structure with widget tests so the keypad cannot regress back to an unstable layout.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Add keypad structure tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add widget coverage that opens the manual barcode dialog and asserts:
- the dialog appears
- digit keys `1-9` exist
- the keypad uses a fixed grid widget
- the bottom row still contains `Delete`, `0`, and submit

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL because the keypad still uses `Wrap`.

### Task 2: Replace the keypad layout and improve styling

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal implementation**

- Replace the digit `Wrap` with a fixed 3-column grid
- Add stronger visual styling for the display panel and keypad buttons
- Keep the existing key ids and input behavior

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

### Task 3: Focused verification

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Run focused verification**

Run:

```bash
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
```

Expected: PASS with the keypad structure and interaction behavior covered.
