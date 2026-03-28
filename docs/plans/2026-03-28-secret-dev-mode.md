# Secret Dev Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a hidden persistent dev-mode toggle on the account page that switches the app between the production and development APIs after a 5-tap zone gesture plus PIN entry.

**Architecture:** Introduce a persisted app-environment source of truth, boot the provider tree from the resolved environment, and let the account page request environment toggles through that controller. The app shell rebuilds on change, clears session state, and shows a small top-left diagonal `DEV` ribbon while the development API is active.

**Tech Stack:** Flutter, Provider, Flutter Secure Storage, widget tests

---

### Task 1: Environment Configuration And Persistence

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\core\config\app_config.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\core\storage\secure_token_storage.dart`
- Create: `C:\Users\Osman\Desktop\putaway app\lib\core\config\app_environment_controller.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\core\config\app_environment_controller_test.dart`

**Step 1: Write the failing test**
- Add tests proving the environment defaults to production, persists development mode, and maps to the correct API base URL.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/core/config/app_environment_controller_test.dart`

**Step 3: Write minimal implementation**
- Add an environment model and config factory helpers.
- Extend secure storage with environment read/write methods.
- Implement a change-notifier controller that loads, persists, and toggles the current environment.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/core/config/app_environment_controller_test.dart`

### Task 2: Bootstrap Rebuild Path And DEV Badge

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\main.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\widgets\putaway_app.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\widgets\putaway_app_test.dart`

**Step 1: Write the failing test**
- Add tests proving the app shell shows a yellow top-left diagonal `DEV` ribbon only in development mode and continues to support the existing routed-content behavior.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

**Step 3: Write minimal implementation**
- Bootstrap the app from the environment controller.
- Rebuild the provider tree with the current `AppConfig`.
- Add a global badge overlay when the active environment is development.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

### Task 3: Secret Zone Gesture And PIN Flow

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\pages\account_page.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\pages\account_page_test.dart`

**Step 1: Write the failing test**
- Add tests proving five taps on the zone row open a PIN dialog, the correct PIN toggles the environment, and the wrong PIN leaves it unchanged.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/shared/pages/account_page_test.dart`

**Step 3: Write minimal implementation**
- Make the zone row tappable.
- Add local tap counting and a PIN dialog.
- Call the environment controller toggle method and show success or failure feedback.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/shared/pages/account_page_test.dart`

### Task 4: Session Reset On Environment Switch

**Files:**
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\main.dart`
- Modify: `C:\Users\Osman\Desktop\putaway app\lib\shared\providers\app_providers.dart`
- Test: `C:\Users\Osman\Desktop\putaway app\test\shared\widgets\putaway_app_test.dart`

**Step 1: Write the failing test**
- Add a test proving an environment switch clears the authenticated session before the app rebuild completes.

**Step 2: Run test to verify it fails**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

**Step 3: Write minimal implementation**
- Clear persisted tokens and in-memory session as part of the environment switch sequence.
- Keep the behavior centralized in the bootstrap/controller so the account page stays thin.

**Step 4: Run test to verify it passes**
- Run: `flutter test test/shared/widgets/putaway_app_test.dart`

### Task 5: Verification

**Files:**
- Verify touched config, startup, and account-page files

**Step 1: Run focused tests**
- Run: `flutter test test/core/config/app_environment_controller_test.dart test/shared/widgets/putaway_app_test.dart test/shared/pages/account_page_test.dart`

**Step 2: Run targeted analysis**
- Run: `dart analyze lib/core/config/app_config.dart lib/core/config/app_environment_controller.dart lib/core/storage/secure_token_storage.dart lib/main.dart lib/shared/pages/account_page.dart lib/shared/widgets/putaway_app.dart test/core/config/app_environment_controller_test.dart test/shared/widgets/putaway_app_test.dart test/shared/pages/account_page_test.dart`

**Step 3: Re-run any existing related regression tests if needed**
- Run: `flutter test test/features/app_update/data/version_remote_data_source_test.dart`
