# Worker Page Scanner Consistency Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Standardize worker task scanner fields so they autofocus reliably and clear stale scan text after 2 seconds, including the cycle count second page.

**Architecture:** Keep the change inside `WorkerTaskDetailsPage` by extending the hidden scanner field handling. Reuse the existing focus restoration flow, add short-lived clear timers for stale raw text, and introduce a small cycle count detail barcode validation state so quantity enablement does not depend on the text remaining visible.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the cycle count second-page scanner behavior with failing tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add focused widget tests that:
- open a cycle count item manually
- verify the hidden barcode field is autofocus-enabled
- enter the correct barcode
- advance fake time by 2 seconds
- verify the hidden barcode field clears
- verify the quantity field stays enabled after the clear

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: FAIL because the cycle count detail barcode field does not currently auto-clear and quantity enablement still depends on the raw text staying present.

**Step 3: Write minimal implementation**

Add a cycle count detail barcode validation state and apply the stale-clear timer to that field.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded`
Expected: PASS

### Task 2: Apply the same stale-clear pattern across worker task scanner inputs

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Standardize worker-page scanner clearing**

- keep autofocus and focus restoration on worker task hidden scanner fields
- clear stale raw text on a 2-second timer where worker task scanner fields remain visible
- preserve existing validation and page-flow behavior

**Step 2: Verify**

Run:

```bash
dart analyze lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --reporter expanded
```

Expected: PASS
