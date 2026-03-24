# Arabic Full Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace remaining hardcoded English UI strings so the main app pages render fully in Arabic when the locale is `ar`.

**Architecture:** Keep the existing `AppLocalizations` setup and extend the ARB files with the remaining page-level strings. Update pages to read all user-visible copy from `context.l10n`, then cover the main worker, inbound, and move flows with Arabic widget assertions.

**Tech Stack:** Flutter, Material, `flutter_gen` l10n, Provider, widget tests

---

### Task 1: Add Missing Localization Keys

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_ar.arb`

**Step 1: Write the failing test**

Add/adjust a localization smoke assertion in an existing widget test that currently expects hardcoded English on one target page when locale is Arabic.

**Step 2: Run test to verify it fails**

Run: `flutter test <target-test> --plain-name "<arabic case>"`
Expected: FAIL because the page still renders English strings.

**Step 3: Write minimal implementation**

Add ARB keys for the remaining dashboard, inbound, move, and shared-page labels, hints, button text, dialogs, and snackbar messages.

**Step 4: Run test to verify it passes**

Run the same targeted test.
Expected: PASS once the generated localizations resolve the new keys.

### Task 2: Localize Dashboard Worker Pages

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing test**

Add Arabic widget assertions for the worker home/task details labels that are still hardcoded.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
Expected: FAIL on hardcoded English labels.

**Step 3: Write minimal implementation**

Replace user-visible hardcoded strings with `context.l10n` and use existing localized messages where available.

**Step 4: Run test to verify it passes**

Run the targeted dashboard tests.
Expected: PASS.

### Task 3: Localize Inbound Pages

**Files:**
- Modify: `lib/features/inbound/presentation/pages/inbound_home_page.dart`
- Modify: `lib/features/inbound/presentation/pages/create_inbound_page.dart`

**Step 1: Write the failing test**

Add Arabic assertions for inbound entry points and create-receipt form labels/messages.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: FAIL on English labels.

**Step 3: Write minimal implementation**

Move inbound page text, scan prompts, form labels, button text, and snackbar copy to `context.l10n`.

**Step 4: Run test to verify it passes**

Run the targeted inbound tests.
Expected: PASS.

### Task 4: Localize Move/Lookup Pages

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_result_page.dart`

**Step 1: Write the failing test**

Add Arabic assertions for adjustment form labels in the lookup result page.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: FAIL on English labels.

**Step 3: Write minimal implementation**

Replace adjustment form labels and hints with localization keys.

**Step 4: Run test to verify it passes**

Run the targeted move tests.
Expected: PASS.

### Task 5: Verification Sweep

**Files:**
- Modify as needed based on residual hardcoded strings discovered during the sweep

**Step 1: Search for residual hardcoded user-facing English**

Run a repo search over `lib/` for `labelText`, `hintText`, `Text('...')`, dialog titles, and snackbar content.

**Step 2: Fix remaining strings**

Replace the remaining page-level user-visible strings with ARB-backed values.

**Step 3: Run focused verification**

Run the dashboard, inbound, move, and localization smoke tests.

**Step 4: Commit**

```bash
git add l10n lib test docs/plans/2026-03-16-arabic-full-support.md
git commit -m "feat: complete Arabic localization pass"
```
