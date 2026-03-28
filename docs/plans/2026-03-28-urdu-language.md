# Urdu Language Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Urdu as a supported app language across the warehouse app with correct RTL behavior and worker-facing Urdu copy.

**Architecture:** Add `ur` to the Flutter localization pipeline, centralize locale and RTL helpers, then convert active user-facing screens from English/Arabic branching to generated localization or a shared three-language helper. Use TDD to prove locale switching and Urdu rendering before broad UI edits.

**Tech Stack:** Flutter, Provider, Flutter gen_l10n, widget tests

---

### Task 1: Locale Foundation

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\providers\locale_controller.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\l10n\l10n.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\widgets\putaway_app.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\widgets\putaway_app_test.dart`

**Step 1: Write the failing test**
- Add a test that pumps `PutawayApp` with locale `ur` and asserts Urdu is included in `supportedLocales`.
- Add a test that verifies the shared helper treats Urdu as RTL.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

**Step 3: Write minimal implementation**
- Add supported locale `Locale('ur')`.
- Teach `LocaleController` to accept only supported language codes.
- Extend shared l10n helpers with `languageCode`, `isUrduLocale`, `isRtlLocale`, and a three-language text picker.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

### Task 2: Generated Urdu Localizations

**Files:**
- Create: `C:\Users\Osman\Desktop\putaway app\l10n\app_ur.arb`
- Modify: `C:\Users\Osman\Desktop\putaway app\l10n\app_en.arb`
- Modify: `C:\Users\Osman\Desktop\putaway app\l10n\app_ar.arb`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\localization_smoke_test.dart`

**Step 1: Write the failing test**
- Add a test that pumps a localized page in Urdu and expects the Urdu home title.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/shared/localization_smoke_test.dart`

**Step 3: Write minimal implementation**
- Add `app_ur.arb` with Urdu translations for existing ARB keys.
- Regenerate localization output with `flutter gen-l10n`.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/shared/localization_smoke_test.dart`

### Task 3: Language Pickers And Account Flow

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\auth\presentation\pages\login_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\pages\account_page.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\auth\login_page_loading_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\pages\account_page_test.dart`

**Step 1: Write the failing test**
- Add tests that verify Urdu can be selected from login and account pages.
- Add tests that verify Urdu labels render in those selectors and the change password flow uses Urdu copy.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/auth/login_page_loading_test.dart test/shared/pages/account_page_test.dart`

**Step 3: Write minimal implementation**
- Expand language switchers to include Urdu.
- Replace Arabic-only direction and string branches with shared locale helpers or generated strings.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/auth/login_page_loading_test.dart test/shared/pages/account_page_test.dart`

### Task 4: Lookup And Adjustment Urdu Support

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\move\presentation\pages\item_lookup_result_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\move\presentation\pages\item_lookup_scan_dialog.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\move\presentation\pages\location_lookup_result_page.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\move\presentation\pages\item_lookup_flow_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\move\presentation\pages\item_lookup_scan_dialog_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\move\presentation\pages\location_lookup_result_page_test.dart`

**Step 1: Write the failing test**
- Add Urdu widget expectations for lookup, adjust, scan dialog, and location result labels.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart`

**Step 3: Write minimal implementation**
- Convert inline English/Arabic strings to three-language rendering for the move feature pages.
- Use RTL-aware alignment where needed.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart`

### Task 5: Dashboard And Inbound Urdu Support

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\dashboard\presentation\pages\worker_home_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\dashboard\presentation\pages\worker_task_details_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\dashboard\presentation\shared\task_visuals.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\inbound\presentation\pages\create_inbound_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\inbound\presentation\pages\inbound_home_page.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\features\inbound\presentation\pages\inbound_receipt_page.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\dashboard\presentation\pages\worker_home_page_lookup_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\dashboard\presentation\pages\worker_task_details_page_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\inbound\presentation\pages\inbound_home_page_test.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\features\inbound\presentation\pages\inbound_receipt_page_test.dart`

**Step 1: Write the failing test**
- Add Urdu expectations for representative worker home, task detail, inbound home, and inbound receipt strings.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 3: Write minimal implementation**
- Replace inline English/Arabic branching in dashboard and inbound screens with shared locale helpers or generated localization.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

### Task 6: Full Verification

**Files:**
- Verify touched files and generated localization output

**Step 1: Run targeted generation and tests**
- Run: `flutter gen-l10n`
- Run: `flutter test test/shared/localization_smoke_test.dart test/shared/widgets/putaway_app_test.dart test/auth/login_page_loading_test.dart test/shared/pages/account_page_test.dart test/features/move/presentation/pages/item_lookup_flow_test.dart test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart test/features/move/presentation/pages/location_lookup_result_page_test.dart test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart test/features/inbound/presentation/pages/inbound_receipt_page_test.dart`

**Step 2: Run broader regression check**
- Run: `flutter test`

**Step 3: Review for mixed-language leftovers**
- Search for remaining Arabic-only language branching and resolve any worker-facing misses.
