# Item Lookup Scan Popup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Item Lookup open a scan popup immediately, then navigate to a separate results page that displays item image and location quantities.

**Architecture:** Keep lookup state in `ItemLookupController`, split UI responsibilities into an entry page (scan popup + routing) and a result page (data rendering). Route scanned barcode through GoRouter path params.

**Tech Stack:** Flutter, Provider, GoRouter, flutter_test.

---

### Task 1: Add failing widget tests for popup and navigation

**Files:**
- Create: `test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 1: Write the failing test**
- Add test expecting scan popup to appear when opening `ItemLookupPage`.
- Add test expecting submit to navigate to results route.

**Step 2: Run test to verify it fails**
Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: FAIL because current page does not auto-popup/navigate this way.

**Step 3: Write minimal implementation**
- None in this task.

**Step 4: Run test to verify it still fails correctly**
Run: same command.
Expected: FAIL due missing behavior, not test syntax.

### Task 2: Implement scan popup entry flow

**Files:**
- Modify: `lib/features/move/presentation/pages/item_lookup_page.dart`

**Step 1: Write/extend failing test**
- Ensure test covers dialog text and scan submit validation.

**Step 2: Run test to verify it fails**
Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: FAIL before code.

**Step 3: Write minimal implementation**
- On first frame, show dialog with barcode input.
- On submit, navigate to result route with barcode path param.

**Step 4: Run test to verify it passes**
Run: same command.
Expected: PASS for popup and navigation assertions.

### Task 3: Implement dedicated result page

**Files:**
- Create: `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- Modify: `lib/shared/providers/router_provider.dart`

**Step 1: Write failing test for result rendering**
- Extend test to open result route and verify item name and location quantities.

**Step 2: Run test to verify it fails**
Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: FAIL because result page route/UI missing.

**Step 3: Write minimal implementation**
- Add results page, call `controller.lookup(barcode)` once in initState.
- Render loading/error/success states using existing summary data.
- Add `/item-lookup/result/:barcode` route.

**Step 4: Run test to verify it passes**
Run: same command.
Expected: PASS.

### Task 4: Final verification and cleanup

**Files:**
- Modify: files from previous tasks as needed

**Step 1: Format**
Run: `dart format lib/features/move/presentation/pages/item_lookup_page.dart lib/features/move/presentation/pages/item_lookup_result_page.dart lib/shared/providers/router_provider.dart test/features/move/presentation/pages/item_lookup_flow_test.dart`

**Step 2: Analyze**
Run: `flutter analyze`
Expected: 0 issues.

**Step 3: Run tests**
Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart`
Expected: PASS.

Run (optional broader confidence): `flutter test`

**Step 4: Commit**
```bash
git add lib/features/move/presentation/pages/item_lookup_page.dart lib/features/move/presentation/pages/item_lookup_result_page.dart lib/shared/providers/router_provider.dart test/features/move/presentation/pages/item_lookup_flow_test.dart docs/plans/2026-03-04-item-lookup-scan-popup-design.md docs/plans/2026-03-04-item-lookup-scan-popup.md
git commit -m "feat: add scan popup and separate item lookup results page"
```
