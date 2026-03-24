# Login Single Loader Design

Date: 2026-03-16

## Goal

Show only one loading indicator during login and prevent interaction with the login form while the request is in progress.

## Problem

The login flow currently renders two loading indicators:

- a local spinner inside the `Sign In` button
- a global centered spinner from the app loading overlay

The global overlay also paints over the screen without blocking input, so the user can still tap into fields while login is pending.

## Chosen approach

Keep the global centered loader as the single source of loading feedback and remove the local button spinner.

- Remove the `CircularProgressIndicator` from the `Sign In` button.
- Change the global loading overlay into a real blocking barrier.
- Disable login text fields while submitting so the page also behaves correctly in local widget contexts.

## Scope

- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/shared/widgets/global_loading_listener.dart`
- `test/auth/login_page_loading_test.dart`

## Behavioral rules

- Only one spinner should be visible during login.
- The centered global loader should remain visible during login.
- The login form should not accept interaction while submitting.
- The `Sign In` button should stay visible but disabled while submitting.

## Non-goals

- Changing login validation rules
- Changing auth navigation
- Changing error message behavior
