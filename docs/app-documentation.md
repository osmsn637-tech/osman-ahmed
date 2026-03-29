# Wherehouse App Documentation

## Overview

`wherehouse` is a Flutter mobile client for warehouse operations. It is built around scanner-first flows for authentication, worker task execution, inbound receiving, item lookup, and stock adjustment. The codebase follows a feature-oriented Clean Architecture style with Provider for dependency injection/state, GoRouter for navigation, Dio for networking, and Flutter Secure Storage for persisted secrets and session data.

The app currently supports:

- Authentication against the QEU backend with persisted session restore
- Role-aware home routing for worker and inbound users
- Worker task execution and task detail workflows
- Inbound PO scanning and receipt processing
- Item lookup by barcode or location
- Stock adjustment from item lookup results
- Account management, password change, sign out, and language switching
- English, Arabic, and Urdu localization with RTL support for Arabic and Urdu
- Android force-update gating
- A persisted internal dev-mode environment switch
- A standalone training entry point for the adjust-item flow

## Product Scope

### Worker role

- Opens the worker home experience from the main scaffold
- Sees current and completed tasks
- Can start and complete warehouse tasks
- Can report task issues and attach a photo
- Can open quick actions for item lookup and stock adjustment

### Inbound role

- Opens the inbound home experience from the main scaffold
- Can scan a PO to open the inbound receipt flow
- Can receive items line by line inside the receipt detail workflow
- Can also use the shared item lookup flow

### Shared account and settings

- View account details, phone, role, and zone
- Change app language
- Change password
- Sign out
- Internal: switch between production and development API environments through the hidden zone-tap flow

## High-Level Architecture

The app is organized into five main layers/folders under `lib/`:

- `core/`
  Shared infrastructure such as configuration, networking, auth persistence, storage, and error mapping.
- `features/`
  Domain/data/presentation code grouped by business capability (`auth`, `dashboard`, `inbound`, `move`, `app_update`).
- `shared/`
  Cross-feature UI, localization helpers, providers, navigation, theme, and scanner support.
- `training/`
  Standalone app entry points used for guided internal training flows.
- `flutter_gen/`
  Generated localization artifacts.

The architectural pattern is practical Clean Architecture:

- `data/` talks to APIs and converts raw responses into models
- `domain/` contains entities, repositories, and use cases
- `presentation/` contains controllers/providers, pages, dialogs, and widgets

## Runtime Boot Flow

App startup is environment-aware and happens in this order:

1. `lib/main.dart`
   Loads the persisted environment selection before booting the UI.
2. `lib/shared/widgets/app_bootstrap.dart`
   Wraps the app in an `AppEnvironmentController` and rebuilds the provider tree when the environment changes.
3. `lib/shared/providers/app_providers.dart`
   Creates all repositories, API clients, controllers, and the router from the active `AppConfig`.
4. `lib/shared/widgets/putaway_app.dart`
   Builds `MaterialApp.router`, wires localization, checks force updates, and shows the global dev ribbon when the development API is active.

This design lets the app switch API environments without changing build flavors.

## Environment Configuration

The app supports two runtime environments:

- Production: `https://api.qeu.info`
- Development: `https://api.qeu.app`

The active environment is derived from:

- `lib/core/config/app_config.dart`
- `lib/core/config/app_environment_controller.dart`
- `lib/core/storage/secure_token_storage.dart`

### Default environment

- Fresh installs or missing environment values default to production.
- The last selected environment is persisted and restored on future launches.

### Hidden dev mode

There is an internal environment toggle on the account page:

1. Open the account page.
2. Tap the zone row 5 times.
3. Enter PIN `564238`.
4. The app toggles between production and development.

What happens on toggle:

- The selected environment is persisted.
- Auth/session storage is cleared.
- The provider tree is rebuilt using the new `AppConfig`.
- The app shows a yellow `DEV` ribbon in the top-left corner while the development API is active.

## Navigation

Routing is defined in `lib/shared/providers/router_provider.dart`.

### Main routes

| Route | Purpose |
| --- | --- |
| `/login` | Login page |
| `/home` | Main scaffold with role-aware home tab |
| `/inbound/receipt/:id` | Inbound receipt flow |
| `/item-lookup/result/:barcode` | Item lookup result page, optionally in adjust mode |
| `/location-lookup/result/:barcode` | Location lookup result page |
| `/account` | Account page |

### Redirect rules

- Unauthenticated users are redirected to `/login`.
- Authenticated users hitting `/login` are redirected to `/home`.

## Main User Flows

### 1. Authentication

Primary files:

- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/providers/auth_controller.dart`
- `lib/features/auth/presentation/providers/login_form_provider.dart`
- `lib/features/auth/presentation/providers/session_provider.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`

Behavior:

- Login is API-backed.
- The login page supports English, Arabic, and Urdu.
- Sessions are restored from secure storage on launch when possible.
- Token refresh is handled through the networking stack.
- Sign out clears persisted auth data.

### 2. Main scaffold and role-aware home

Primary files:

- `lib/shared/widgets/main_scaffold.dart`
- `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- `lib/features/inbound/presentation/pages/inbound_home_page.dart`

Behavior:

- The bottom navigation currently exposes `Home` and `Account`.
- `Home` resolves by role:
  - inbound users go to `InboundHomePage`
  - everyone else currently goes to `WorkerHomePage`

### 3. Worker home and task execution

Primary files:

- `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`

Behavior:

- Shows overview metrics for available, active, and completed tasks
- Lists current tasks and completed tasks
- Supports pull-to-refresh and explicit refresh from the app bar
- Lets the user:
  - start pending tasks
  - open in-progress tasks
  - view completed tasks
  - use quick actions for lookup and adjust

The task details page is the most complex workflow in the app. It adapts to task type and supports flows such as:

- receive
- refill
- return
- adjustment
- cycle count

Additional task behaviors include:

- barcode and location validation
- explicit next-step prompts during scanner-heavy task flows
- stronger inline scan success and error feedback
- item lookup during refill/adjustment flows
- progress save/continue for cycle count
- reporting task problems
- optional photo capture using `image_picker`

### 4. Inbound receiving

Primary files:

- `lib/features/inbound/presentation/pages/inbound_home_page.dart`
- `lib/features/inbound/presentation/pages/inbound_receipt_page.dart`
- `lib/features/inbound/presentation/controllers/inbound_controller.dart`
- `lib/features/inbound/presentation/controllers/inbound_receipt_controller.dart`

Behavior:

- Inbound users can scan a PO from the inbound home page.
- Successful scan results navigate to `/inbound/receipt/:id`.
- The inbound receipt flow has two major states:
  - receipt list view with scanned/matched items
  - item detail view for confirming quantity and expiration date

Inbound receiving is scanner-first:

- hidden scan fields keep focus for hardware scanner input
- manual barcode dialogs exist as fallback
- receipt items can be opened by scanning or by tapping the line item
- next-step prompts explain whether the user should start, scan, or confirm
- scan validation feedback is surfaced inline with stronger success/error states

### 5. Item lookup and stock adjustment

Primary files:

- `lib/features/move/presentation/pages/item_lookup_result_page.dart`
- `lib/features/move/presentation/pages/location_lookup_result_page.dart`
- `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- `lib/features/move/presentation/controllers/item_lookup_controller.dart`
- `lib/features/move/presentation/controllers/item_adjustment_controller.dart`
- `lib/features/move/presentation/controllers/location_lookup_controller.dart`

Behavior:

- Lookup can start from worker home or inbound home.
- The scan dialog can resolve either:
  - item barcode lookup
  - location lookup
- Item lookup result page shows:
  - item identity
  - image
  - total quantity
  - shelf locations
  - bulk locations

Adjustment mode reuses the same page and adds an adjustment panel for:

- selecting or typing a location
- entering a new quantity
- confirming the stock adjustment

### 6. Account page

Primary files:

- `lib/shared/pages/account_page.dart`
- `lib/shared/providers/locale_controller.dart`

Behavior:

- Displays phone, canonical role, and normalized zone
- Supports language switching between English, Arabic, and Urdu
- Supports password change through the auth repository
- Supports sign out
- Hosts the hidden environment-switch flow on the zone row

## Localization

Primary files:

- `l10n/app_en.arb`
- `l10n/app_ar.arb`
- `l10n/app_ur.arb`
- `lib/shared/l10n/l10n.dart`
- generated localization files under `lib/flutter_gen/gen_l10n/`

Supported locales:

- English (`en`)
- Arabic (`ar`)
- Urdu (`ur`)

Notes:

- Arabic and Urdu are both treated as RTL.
- Some screens use generated `AppLocalizations`.
- Some brownfield screens still use `context.trText(...)` for three-language inline text selection.
- The login and account flows already expose Urdu in the UI.

## App Update / Force Update

Primary files:

- `lib/features/app_update/presentation/controllers/app_update_controller.dart`
- `lib/features/app_update/presentation/services/app_update_runtime_services.dart`
- `lib/features/app_update/data/datasources/app_update_remote_data_source.dart`
- `version.json`

Behavior:

- Force update is enforced only on Android.
- Installed version is read via `package_info_plus`.
- The remote minimum-version metadata is fetched from the GitHub release asset configured in `AppConfig`.
- `PutawayApp` blocks routed content with a force-update gate when the installed app is below the minimum supported version.

Current version metadata source:

- GitHub release asset: `version.json`

## Dependency Injection and State

The app is wired through `appProviders(...)` in `lib/shared/providers/app_providers.dart`.

Important provider groups:

- Configuration and infrastructure
  - `AppConfig`
  - `ErrorMapper`
  - `SecureTokenStorage`
  - `TokenRepository`
  - `DioClient`
  - `ApiClient`
- Auth
  - `AuthRepository`
  - `LoginUseCase`
  - `AuthController`
  - `LoginFormController`
  - `SessionController`
- Dashboard/task execution
  - dashboard/task repositories and use cases
  - `DashboardController`
  - `WorkerTasksController`
- Inbound
  - inbound repository and use case
  - `InboundController`
- Move/lookup/adjust
  - item repository and use cases
- Shared UI/runtime
  - `LocaleController`
  - `NavigationController`
  - `ScannerProvider`
  - `GoRouter`
  - `AppUpdateController`

## Scanner and Manual Entry Strategy

The app is designed for scanner-first warehouse usage.

Patterns used across flows:

- hidden text fields kept focused for scanner input
- manual keypad/text dialogs as fallback
- debounce around scan processing
- focus restoration when the app resumes from the background

You can see these patterns clearly in:

- `worker_task_details_page.dart`
- `inbound_receipt_page.dart`
- `item_lookup_scan_dialog.dart`

## Training Entry Point

Primary file:

- `lib/training/main_adjust_training.dart`

Purpose:

- Provides a guided training build for the adjust-item flow
- Reuses production UI patterns where practical
- Supports English, Arabic, and Urdu

Training locale behavior:

- Controlled by `TRAINING_LOCALE`
- Defaults to `en`
- Example values: `en`, `ar`, `ur`

Example run:

```bash
flutter run -t lib/training/main_adjust_training.dart --dart-define=TRAINING_LOCALE=ur
```

## Project Structure

```text
lib/
  core/
    auth/
    config/
    errors/
    network/
    storage/
    utils/
  features/
    app_update/
    auth/
    dashboard/
    inbound/
    move/
  shared/
    l10n/
    navigation/
    pages/
    providers/
    scanner/
    theme/
    ui/
    utils/
    widgets/
  training/
```

## Local Development

### Requirements

- Flutter SDK compatible with `sdk: >=3.4.0 <4.0.0`
- Android tooling for mobile runs

### Install dependencies

```bash
flutter pub get
```

### Run the main app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

### Analyze

```bash
dart analyze
```

## Release and Versioning Notes

Current app version in `pubspec.yaml`:

- `1.2.2+1`

For Android force-update behavior to work correctly during releases:

1. Update `pubspec.yaml` version.
2. Update the release `version.json`.
3. Publish the APK and `version.json` asset to the expected GitHub release.

## Maintenance Guide

### Adding a new page

1. Create the page in the appropriate `features/.../presentation/pages/` folder.
2. Add any controller/use case/repository wiring in `app_providers.dart`.
3. Register the route in `router_provider.dart` if it needs deep-link style navigation.
4. Add widget tests for the new flow.

### Adding a new localized string

1. Add the key to:
   - `l10n/app_en.arb`
   - `l10n/app_ar.arb`
   - `l10n/app_ur.arb`
2. Regenerate localizations if needed.
3. Replace hard-coded text or extend `context.trText(...)` usage.

### Adding a new backend service

1. Add the remote data source under the relevant feature `data/` layer.
2. Expose a repository in the `domain/` layer.
3. Add a use case if the action is business-facing.
4. Register all required providers in `app_providers.dart`.

### Extending the training app

1. Add a new training entry point under `lib/training/`.
2. Reuse existing feature pages/controllers when possible.
3. Keep the training locale helpers aligned with the main app locale support.

## Known Documentation Boundaries

This document covers the Flutter client as it exists in this repository. It does not include:

- backend API schema documentation
- deployment pipeline documentation
- server-side authentication internals
- warehouse business SOPs outside what is encoded in the UI flows

If those are needed too, they should be written as companion docs rather than inferred from the mobile codebase.
