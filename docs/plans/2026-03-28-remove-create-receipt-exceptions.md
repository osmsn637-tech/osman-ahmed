# Remove Create Receipt And Exceptions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the dead Create Receipt and Exceptions user-facing flows from the app, docs, and localization.

**Architecture:** The change is a shallow feature removal. We will prove the router no longer exposes the deleted routes, then remove the dead pages, route entries, localization keys, and documentation references while leaving dashboard exception internals alone.

**Tech Stack:** Flutter, GoRouter, Provider, Flutter l10n, flutter_test

---

### Task 1: Add the failing router regression test

**Files:**
- Create: `test/shared/providers/router_provider_test.dart`
- Modify: none
- Test: `test/shared/providers/router_provider_test.dart`

**Step 1: Write the failing test**

Add a widget test that builds the app router and asserts the top-level route paths do not include:

- `/inbound/create`
- `/exceptions-tab`
- `/exceptions`

**Step 2: Run test to verify it fails**

Run: `flutter test test/shared/providers/router_provider_test.dart`

Expected: FAIL because the current router still includes those paths.

**Step 3: Keep the test unchanged**

Do not weaken the assertions. The production code should change to satisfy the test.

### Task 2: Remove the dead routes and pages

**Files:**
- Modify: `lib/shared/providers/router_provider.dart`
- Delete: `lib/features/inbound/presentation/pages/create_inbound_page.dart`
- Delete: `lib/features/dashboard/presentation/pages/exceptions_page.dart`
- Delete: `lib/shared/pages/more_page.dart`

**Step 1: Remove the imports and route entries**

Delete the router entries for:

- `/inbound/create`
- `/exceptions-tab`
- `/exceptions`

**Step 2: Delete the dead page files**

Remove the page files that are no longer reachable.

**Step 3: Run the targeted test**

Run: `flutter test test/shared/providers/router_provider_test.dart`

Expected: PASS

### Task 3: Remove stale localization and docs

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_ar.arb`
- Modify: `l10n/app_ur.arb`
- Modify: `docs/app-documentation.md`
- Modify: `docs/2026-03-15-remaining-api-audit.md`

**Step 1: Remove dead localization keys**

Delete the strings that only supported the removed UI:

- `moreExceptions`
- `exceptionsTitle`
- `inboundCreateDialogTodo`

Leave unrelated inbound strings untouched.

**Step 2: Regenerate localizations**

Run: `flutter gen-l10n`

Expected: Generated localization files no longer include the removed keys.

**Step 3: Update docs**

Remove route and feature references to Create Receipt and Exceptions from the documentation.

### Task 4: Final verification

**Files:**
- Verify all edited files

**Step 1: Run focused verification**

Run: `flutter test test/shared/providers/router_provider_test.dart`

Expected: PASS

**Step 2: Run full verification**

Run: `flutter test`

Expected: PASS

Run: `dart analyze`

Expected: no errors; info-only lint output is acceptable if unchanged from baseline.
