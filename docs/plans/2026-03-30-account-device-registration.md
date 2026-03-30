# Account Device Registration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a hidden 3-tap account-name trigger that opens a device registration dialog and posts the typed device name plus native device metadata to the mobile device registration endpoint.

**Architecture:** Reuse the existing Android scanner method channel to expose native device metadata, add a small device-management API slice in the app data layer, and keep the account page responsible only for collecting the editable device name and invoking registration. The dialog will submit `device.deviceId` from user input and fill `deviceSerial`, `model`, and `osVersion` from the platform service.

**Tech Stack:** Flutter, Provider, Dio `ApiClient`, Android `MethodChannel`, Flutter widget tests.

---

### Task 1: Lock the UI trigger and payload behavior with tests

**Files:**
- Modify: `test/shared/pages/account_page_test.dart`
- Create: `test/features/device_management/data/datasources/device_management_remote_data_source_test.dart`

**Step 1: Write the failing widget tests**
- Add a test that tapping the account name 3 times opens a register dialog.
- Add a test that submitting the dialog sends the typed device name and closes on success.

**Step 2: Run the widget test to verify it fails**
- Run: `flutter test test/shared/pages/account_page_test.dart`
- Expected: FAIL because the account name does not yet open a register dialog or submit registration.

**Step 3: Write the failing datasource test**
- Add a test that `registerDevice()` posts:
```json
{
  "device": {
    "deviceId": "Picked Name",
    "deviceSerial": "serial-or-android-id",
    "model": "TC21",
    "osVersion": "13"
  }
}
```

**Step 4: Run the datasource test to verify it fails**
- Run: `flutter test test/features/device_management/data/datasources/device_management_remote_data_source_test.dart`
- Expected: FAIL because the datasource and endpoint do not exist yet.

### Task 2: Add the device registration app layer

**Files:**
- Modify: `lib/core/constants/app_endpoints.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Create: `lib/features/device_management/data/datasources/device_management_remote_data_source.dart`
- Create: `lib/features/device_management/domain/repositories/device_management_repository.dart`
- Create: `lib/features/device_management/data/repositories/device_management_repository_impl.dart`
- Create: `lib/shared/device/device_metadata.dart`
- Create: `lib/shared/device/device_metadata_service.dart`

**Step 1: Add the endpoint**
- Add `/mobile/v1/devices/register` to `AppEndpoints`.

**Step 2: Add the remote datasource**
- Implement `registerDevice()` with the nested `device` request body.

**Step 3: Add the repository**
- Expose a thin `registerDevice()` wrapper that returns `Result<void>`.

**Step 4: Add the device metadata service abstraction**
- Create a Dart model for `deviceSerial`, `model`, and `osVersion`.
- Create a platform-backed service interface/implementation to fetch those values.

**Step 5: Wire providers**
- Register the device metadata service, datasource, and repository in `appProviders`.

### Task 3: Extend the Android bridge

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/putaway_app/MainActivity.kt`

**Step 1: Add a `getDeviceInfo` method-channel call**
- Return a map with `deviceSerial`, `model`, and `osVersion`.

**Step 2: Implement serial fallback**
- Try hardware serial first when accessible.
- Fall back to Android ID if serial access is unavailable.

**Step 3: Keep the scanner channel behavior unchanged**
- Ensure existing scanner methods still work exactly as before.

### Task 4: Add the account-page dialog flow

**Files:**
- Modify: `lib/shared/pages/account_page.dart`

**Step 1: Add the hidden 3-tap name trigger**
- Wrap the visible name label with a tap handler and a stable test key.

**Step 2: Add the register-device dialog**
- One editable field only: device name.
- Validate non-empty input.
- Use platform metadata + repository registration on submit.

**Step 3: Add success and error feedback**
- Close the dialog and show a snackbar on success.
- Keep the dialog open and show the error on failure.

### Task 5: Verify the full change

**Files:**
- Modify as needed from tasks above

**Step 1: Run focused tests**
- `flutter test test/shared/pages/account_page_test.dart`
- `flutter test test/features/device_management/data/datasources/device_management_remote_data_source_test.dart`

**Step 2: Run regression suites**
- `flutter test test/shared/l10n/l10n_test.dart`

**Step 3: Run analyzer on touched files**
- `flutter analyze lib/shared/pages/account_page.dart lib/shared/providers/app_providers.dart lib/core/constants/app_endpoints.dart lib/shared/device/device_metadata.dart lib/shared/device/device_metadata_service.dart lib/features/device_management/data/datasources/device_management_remote_data_source.dart lib/features/device_management/data/repositories/device_management_repository_impl.dart lib/features/device_management/domain/repositories/device_management_repository.dart test/shared/pages/account_page_test.dart test/features/device_management/data/datasources/device_management_remote_data_source_test.dart`
