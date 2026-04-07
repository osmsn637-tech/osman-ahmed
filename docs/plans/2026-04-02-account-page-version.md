# Account Page Version Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show the installed app version at the bottom of the account page using the same `v<version>` display pattern as login.

**Architecture:** The account page will resolve the installed version through the existing `InstalledAppVersionProvider` dependency that is already registered in shared app providers. The page will keep a local state string, render `v--` while unresolved, and update the footer after the async lookup completes.

**Tech Stack:** Flutter, Provider, flutter_test, package_info_plus

---

### Task 1: Add the regression test

**Files:**
- Modify: `test/shared/pages/account_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that injects a fake `InstalledAppVersionProvider`, pumps `AccountPage`, and expects the footer to show `v1.2.5`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/shared/pages/account_page_test.dart`
Expected: FAIL because the account page does not render any version footer yet.

### Task 2: Implement the footer

**Files:**
- Modify: `lib/shared/pages/account_page.dart`

**Step 3: Write minimal implementation**

Load the installed version asynchronously from `InstalledAppVersionProvider`, store it in local state, and render a centered muted footer string at the end of the account page content.

**Step 4: Run test to verify it passes**

Run: `flutter test test/shared/pages/account_page_test.dart`
Expected: PASS with the new footer visible.

### Task 3: Verify the change

**Files:**
- Modify: `lib/shared/pages/account_page.dart`
- Modify: `test/shared/pages/account_page_test.dart`

**Step 5: Run targeted verification**

Run: `flutter test test/shared/pages/account_page_test.dart`
Expected: PASS with no account page regressions.
