# Login Single Loader Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the duplicate login loading spinner and block interaction with the login form while login is running.

**Architecture:** Keep `GlobalLoadingController` as the only spinner source during login. Update the global loading widget to use a real modal barrier and update the login page so its fields are disabled during submission and its button keeps text instead of rendering a second spinner.

**Tech Stack:** Flutter, Dart, Provider, widget tests

---

### Task 1: Add the failing login loading test

**Files:**
- Create: `test/auth/login_page_loading_test.dart`

**Step 1: Write the failing test**

- Build `LoginPage` inside `GlobalLoadingListener` with a delayed fake auth repository.
- Submit valid credentials.
- Assert there is only one `CircularProgressIndicator`.
- Assert a `ModalBarrier` is present.
- Assert the login text fields are disabled while submitting.

**Step 2: Run test to verify it fails**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: FAIL because the button still shows its own spinner and the overlay does not block input

### Task 2: Implement the login loading fix

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/shared/widgets/global_loading_listener.dart`

**Step 1: Write minimal implementation**

- Remove the in-button spinner from `LoginPage`.
- Disable the login text fields while `isSubmitting` is true.
- Replace the passive painted overlay in `GlobalLoadingListener` with a modal barrier plus centered spinner.

**Step 2: Run test to verify it passes**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: PASS

### Task 3: Format and verify

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/shared/widgets/global_loading_listener.dart`
- Create: `test/auth/login_page_loading_test.dart`

**Step 1: Format**

Run: `dart format lib/features/auth/presentation/pages/login_page.dart lib/shared/widgets/global_loading_listener.dart test/auth/login_page_loading_test.dart`

**Step 2: Run focused verification**

Run: `flutter test test/auth/login_page_loading_test.dart`
Expected: PASS

Run: `git diff --check`
Expected: no whitespace errors
