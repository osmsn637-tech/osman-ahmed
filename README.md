# QEU Putaway

Flutter mobile client for warehouse operations. The current app is API-backed
and centered on scanner-first workflows for inbound receiving, worker task
execution, item lookup, and stock adjustment.

## Current product scope

- Real authentication against the QEU backend, with persisted session restore
  and token refresh.
- Role-aware home routing:
  - `inbound` users land on the inbound home flow.
  - other authenticated users currently land on the worker operations flow.
- Worker task execution for active warehouse work, including receive, refill,
  return, adjustment, move-related flows, and cycle count handling.
- Scanner-first item lookup and stock adjustment from the home screen and the
  More menu.
- Inbound receipt lookup by scanned PO, with receipt detail and receiving flow.
- Exceptions list for warehouse issues surfaced by the dashboard API.
- Account management with Arabic/English language switching, change password,
  and sign out.

## Main app flows

### Authentication

- Login screen with English/Arabic toggle.
- Session persistence through secure token storage.
- Automatic session restore on app launch when stored credentials are valid.

### Worker operations

- Role-aware worker home with queue metrics, refresh, and task cards.
- Quick actions for:
  - item lookup
  - stock adjustment
- Task details page adapts to the task type and supports guided completion
  flows, barcode/location validation, reporting issues, and photo attachment
  when reporting problems.

### Inbound operations

- Inbound home with quick actions for:
  - item lookup
  - receive by scanning a PO
- Receipt screen for processing inbound items after the PO scan resolves to a
  receipt from the backend.

### Item lookup and adjustment

- Scanner-first barcode dialog with manual fallback.
- Item lookup result page showing item image, quantity, and parsed locations.
- Adjustment mode for updating stock counts against a selected location.

### Account and settings

- Role and phone display.
- In-app language switch between English and Arabic.
- Change password flow backed by the API.
- Sign out and session clearing.

## Architecture

The app follows a feature-oriented Clean Architecture structure:

- `lib/core`
  Shared configuration, networking, auth/token handling, error mapping, and
  storage.
- `lib/features/auth`
  Login, persisted session restore, and account-related auth actions.
- `lib/features/dashboard`
  Worker task listing, task details, exceptions, and task workflow actions.
- `lib/features/inbound`
  Inbound receipt scanning and receiving flows.
- `lib/features/move`
  Item lookup and stock adjustment.
- `lib/shared`
  Navigation, localization, theme, scaffold, scanner support, and shared UI.

## Tech stack

- Flutter
- Provider
- GoRouter
- Dio
- Flutter Secure Storage
- Image Picker

## Backend configuration

The app currently ships with a static API configuration in
`lib/core/config/app_config.dart`:

- Base URL: `https://api.qeu.info`
- Network logging: enabled

If you need a different backend environment, update `AppConfig.load()`.

## Getting started

```bash
flutter pub get
flutter run
```

## Development checks

```bash
flutter test
flutter analyze
```

## Notes

- The old mock-only supervisor/worker README is no longer accurate for this
  codebase.
- Login now requires valid backend credentials; the app is not documented here
  as a mock-data demo.
- Role aliases from the backend are normalized in code, for example receiver
  style roles map to `inbound` and putaway operator style roles map to
  `worker`.
