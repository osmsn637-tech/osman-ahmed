# Cycle Count API Products Parsing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Parse real `cycle_count` API responses that provide item lines in `products`, while hiding zero-quantity items from the worker cycle count UI.

**Architecture:** Keep the two-page cycle count UI unchanged and adapt the repository/entity parsing layer to normalize `products` into the existing cycle count item model. Use `products` as the preferred source and preserve fallback behavior for older `expectedLines`-style data.

**Tech Stack:** Dart, Flutter, flutter_test

---

### Task 1: Add failing repository coverage for `products` parsing

**Files:**
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add a test with a `cycle_count` payload that includes:

- 3 products with positive quantity
- 2 products with zero quantity

Expect:

- parsed task type is `TaskType.cycleCount`
- `task.cycleCountItems.length` equals only the positive-quantity products
- zero-quantity barcodes are absent

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "parses cycle count products and hides zero quantity items"`
Expected: FAIL because the parser does not currently map `products` into cycle count items.

**Step 3: Write minimal implementation**

Update repository parsing and entity normalization so `products` populates cycle count workflow data / normalized cycle count items.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "parses cycle count products and hides zero quantity items"`
Expected: PASS

### Task 2: Preserve fallback behavior for old cycle count shapes

**Files:**
- Modify: `lib/features/dashboard/domain/entities/task_entity.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`

**Step 1: Write the failing test**

Add a test ensuring that when `products` is missing, existing `expectedLines`-driven cycle count parsing still works.

**Step 2: Run test to verify it fails if fallback was broken**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "cycle count parsing falls back when products are missing"`
Expected: PASS before implementation, and stays PASS after implementation.

**Step 3: Write minimal implementation**

Implement `products`-first, fallback-second parsing:

- if `workflowData['products']` or parsed cycle count workflow products exist, use them
- else fall back to `expectedLines`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart --plain-name "cycle count parsing falls back when products are missing"`
Expected: PASS
