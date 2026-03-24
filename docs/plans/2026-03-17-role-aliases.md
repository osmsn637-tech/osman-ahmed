# Role Aliases Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Map `receiver` to inbound behavior and `putaway operator` to worker behavior across the app without changing unrelated role flows.

**Architecture:** Introduce canonical role normalization in the auth user entity, then consume that canonical role in routing, guards, and account presentation. Cover the alias behavior with focused tests first so the implementation is driven by observed failures.

**Tech Stack:** Flutter, Dart, flutter_test, provider, go_router

---

### Task 1: Add failing alias tests

**Files:**
- Modify: `test/shared/pages/account_page_test.dart`
- Create: `test/features/auth/domain/entities/user_test.dart`

**Step 1: Write the failing test**

Add tests that assert:
- `receiver` is treated as inbound
- `putaway operator` is treated as worker
- the account page shows the inbound label for `receiver`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/domain/entities/user_test.dart test/shared/pages/account_page_test.dart`
Expected: FAIL because the current role helpers and account labeling only recognize the raw canonical values.

**Step 3: Write minimal implementation**

Update the user entity and account page to consume a canonical role instead of repeating raw string checks.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/domain/entities/user_test.dart test/shared/pages/account_page_test.dart`
Expected: PASS

### Task 2: Verify role-aware navigation still resolves correctly

**Files:**
- Modify: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/shared/widgets/role_guard.dart`

**Step 1: Write the failing test**

Add a widget test that boots the role-aware home with a `receiver` user and expects inbound content instead of worker content.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: FAIL because `receiver` does not currently satisfy inbound checks.

**Step 3: Write minimal implementation**

Switch role-aware home and guard logic to use the canonical role abstraction.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: PASS

### Task 3: Run the targeted verification set

**Files:**
- Modify: `lib/features/auth/domain/entities/user.dart`
- Modify: `lib/shared/pages/account_page.dart`
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/shared/widgets/role_guard.dart`

**Step 1: Run the verification command**

Run: `flutter test test/features/auth/domain/entities/user_test.dart test/shared/pages/account_page_test.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 2: Confirm output**

Expected: all targeted alias tests pass with exit code 0.
