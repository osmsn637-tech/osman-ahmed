# Login Form Reset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Clear stale login credentials when the app returns to the login page so the button state and submitted credentials always match the visible empty form.

**Architecture:** Add an explicit reset API to `LoginFormController`, invoke it from `LoginPage` initialization, and bind the page fields to text controllers so visual field contents stay aligned with provider state. Cover the stale-state regression with a focused widget test that recreates the login page with the same provider.

**Tech Stack:** Flutter, Dart, Provider, widget tests

---

### Task 1: Add the failing stale-state regression test

**Files:**
- Modify: `test/auth/login_page_loading_test.dart`

**Step 1: Write the failing test**

- Create a fake auth repository that records login calls.
- Build `LoginPage`, type credentials, then rebuild a fresh `LoginPage` with the same `LoginFormController`.
- Assert the new page has a disabled `Sign In` button and tapping it does not submit the old credentials.

**Step 2: Run test to verify it fails**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: FAIL because the provider still holds the old valid credentials

### Task 2: Implement login form reset

**Files:**
- Modify: `lib/features/auth/presentation/providers/login_form_provider.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart`

**Step 1: Write minimal implementation**

- Add `reset()` to `LoginFormController`.
- Reset the provider when `LoginPage` is created.
- Add `TextEditingController`s to the page and keep them synchronized with the provider reset state.

**Step 2: Run test to verify it passes**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: PASS

### Task 3: Format and verify

**Files:**
- Modify: `lib/features/auth/presentation/providers/login_form_provider.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `test/auth/login_page_loading_test.dart`

**Step 1: Format**

Run: `dart format lib/features/auth/presentation/providers/login_form_provider.dart lib/features/auth/presentation/pages/login_page.dart test/auth/login_page_loading_test.dart`

**Step 2: Run focused verification**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: PASS

Run: `flutter test test/auth/login_page_performance_test.dart`
Expected: PASS
