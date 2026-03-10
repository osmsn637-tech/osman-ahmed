# Receive Task Details Two-Page Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update `receive` task details so workers validate the API barcode on Page 1, then unlock Page 2 for bulk-location validation and completion.

**Architecture:** Keep the existing worker task details route as the single entry point, but branch receive tasks into a dedicated two-page flow with explicit step state. Update task mapping so `product_barcode` is the primary barcode source, then reuse `task.itemBarcode` inside the details page for display and validation.

**Tech Stack:** Flutter, flutter_test, existing dashboard task repository parsing

---

### Task 1: Add failing coverage for API barcode precedence and the two-page receive flow

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing repository test**

Add a test showing that when the API payload includes `product_barcode`, the parsed task uses that value ahead of older barcode-like fields.

**Step 2: Write the failing widget tests**

Add receive-specific tests that assert:
- Page 1 shows item info, `From Inbound`, and the API barcode
- the item image is rendered in a smaller container
- Page 2 content is not available before barcode validation
- validating the barcode unlocks navigation to Page 2
- Page 2 shows bulk location validation and completion

**Step 3: Run tests to verify they fail**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL because `product_barcode` is not yet prioritized and the receive UI is still single-page.

**Step 4: Commit**

```bash
git add test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "test: cover receive barcode mapping and two-page flow"
```

### Task 2: Prioritize `product_barcode` in task mapping

**Files:**
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`

**Step 1: Update barcode parsing**

Change the task parsing fallback order so `product_barcode` is checked before `barcode`, `itemBarcode`, `receiptNumber`, and related legacy fields.

**Step 2: Keep non-receive parsing intact**

Do not change any unrelated task parsing behavior beyond the barcode source precedence.

**Step 3: Run repository test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`

Expected: PASS

**Step 4: Commit**

```bash
git add lib/features/dashboard/data/repositories/task_repository_impl.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart
git commit -m "fix: prefer product barcode in task parsing"
```

### Task 3: Convert receive details into a locked two-page flow

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write minimal receive paging state**

Add receive-only state for:
- current page index
- item validation
- location validation

**Step 2: Build Page 1**

Render only:
- smaller full-fit image
- item name
- barcode
- quantity
- `From Inbound`
- barcode input and validate action

**Step 3: Keep Page 2 locked**

Before barcode validation succeeds:
- do not allow advancing to Page 2
- do not show Page 2 controls as active

**Step 4: Build Page 2**

After barcode validation succeeds, render:
- bulk destination location
- location input
- validate bulk location action
- complete button

**Step 5: Reset downstream state on barcode edits**

If Page 1 barcode input changes after validation:
- relock Page 2
- clear bulk-location validation state

**Step 6: Keep non-receive layout unchanged**

Leave the generic move/refill/general task details path intact.

**Step 7: Run widget test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS

**Step 8: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: split receive task details into two locked pages"
```

### Task 4: Run focused verification

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Run both focused suites**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS

**Step 2: Format touched files**

Run:
- `dart format lib/features/dashboard/data/repositories/task_repository_impl.dart`
- `dart format lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `dart format test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `dart format test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: files formatted without errors

**Step 3: Re-run the focused suites**

Run:
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: PASS after formatting

**Step 4: Commit**

```bash
git add lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart docs/plans/2026-03-10-receive-task-details-design.md docs/plans/2026-03-10-receive-task-details.md
git commit -m "feat: finalize receive two-page validation flow"
```
