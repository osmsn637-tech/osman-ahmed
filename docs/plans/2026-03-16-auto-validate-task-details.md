# Auto Validate Task Details Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove manual validate buttons from worker task details and auto-validate scanned or typed values without requiring duplicate scans.

**Architecture:** Keep all validation logic inside `WorkerTaskDetailsPage`, but trigger it from field change handlers instead of explicit buttons. Add duplicate-value guards so local and remote validation run once per value, then keep the existing validation state and page transitions.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: Lock the new interaction in widget tests

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing tests**

Add focused widget coverage for:
- receive/refill flows auto-validating product input and opening the next page
- auto-validating location input without tapping a button
- generic task flows no longer rendering validate buttons
- remote validation running once per scanned location value

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL because the page still requires button taps.

### Task 2: Move task-detail validation to field change handlers

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal implementation**

- Remove the visible validate buttons for the affected flows.
- Trigger product/location validation from `onChanged` handlers.
- Add guards for in-flight validation and repeated validated values.
- Keep error and success messages intact.

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

### Task 3: Auto-advance after successful validation

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write minimal implementation**

- Advance receive/refill/cycle-count flows automatically when the expected validation succeeds.
- Preserve the current completion gating logic.

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: PASS

### Task 4: Focused verification

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Run focused verification**

Run:

```bash
flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
```

Expected: PASS with the updated auto-validation behavior covered.
