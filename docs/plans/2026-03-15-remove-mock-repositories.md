# Remove Mock Repositories Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the old mock repository files for task, item, and inbound flows, while keeping runtime wiring and tests working.

**Architecture:** Runtime wiring should use real repository implementations where they already exist, and a non-seeded inbound repository implementation where one does not. Tests that currently import mock repository files should switch to test-local fake implementations so production mock files can be deleted entirely.

**Tech Stack:** Flutter, Provider, GoRouter, Dart test/widget test

---

### Task 1: Replace Runtime Mock Wiring

**Files:**
- Modify: `lib/shared/providers/app_providers.dart`
- Create: `lib/features/inbound/data/repositories/inbound_repository_impl.dart`

**Step 1: Write the failing test**

Existing compile-time references are the failure surface: runtime providers still import deleted mock files.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: import/build failure once mock files are removed

**Step 3: Write minimal implementation**

- Switch `ItemRepository` provider to `ItemRepositoryImpl`
- Replace `InboundRepositoryMock` with a non-seeded `InboundRepositoryImpl`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`
Expected: PASS

### Task 2: Replace Test Dependencies On Mock Repository Files

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_task_flow_test.dart`
- Modify: `test/features/move/presentation/pages/item_lookup_flow_test.dart`
- Modify: `test/features/move/presentation/pages/item_lookup_duplicate_keys_test.dart`
- Modify: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`
- Create: `test/support/fake_repositories.dart`

**Step 1: Write the failing test**

Existing imports of the mock repository files become the failure surface.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
Expected: import/build failure once mock files are removed

**Step 3: Write minimal implementation**

- Add reusable test fakes implementing the repository interfaces
- Update affected tests to import and use those fakes

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
Expected: PASS

### Task 3: Delete Old Mock Repository Files

**Files:**
- Delete: `lib/features/dashboard/data/repositories/task_repository_mock.dart`
- Delete: `lib/features/move/data/repositories/item_repository_mock.dart`
- Delete: `lib/features/inbound/data/repositories/inbound_repository_mock.dart`

**Step 1: Write the failing test**

This is covered by the dependency replacement tasks above.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: import/build failure before test fakes are in place

**Step 3: Write minimal implementation**

Delete the old mock repository files after all references are removed.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: PASS
