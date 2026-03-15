# Restore Worker Home Adjust Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore the worker-home `Adjust` quick action while preserving the task-details adjustment flow.

**Architecture:** Reintroduce `Adjust` as a second quick action in `WorkerHomePage` and reuse the existing `_openItemLookup` helper with `ItemLookupPageMode.adjust`. Update the worker-home widget tests to assert both quick actions are rendered.

**Tech Stack:** Flutter, Provider, GoRouter, Flutter widget tests

---

### Task 1: Restore worker-home quick action coverage

**Files:**
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

**Step 1: Write the failing test**

Change the worker-home quick-action assertions so they expect `Adjust` to be visible again.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

Expected: FAIL because the current page only renders `Lookup`.

**Step 3: Write minimal implementation**

Restore the `Adjust` quick action in `WorkerHomePage` using the existing scan dialog helper and `ItemLookupPageMode.adjust`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`

Expected: PASS.
