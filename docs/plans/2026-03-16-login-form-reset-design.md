# Login Form Reset Design

Date: 2026-03-16

## Goal

Ensure the login page always opens with an empty form and disabled `Sign In` button after logout or any return to the login route.

## Problem

`LoginFormController` is provided above the router and survives navigation. When the user logs out, `SessionController` is cleared, but the login form provider still holds the old username and password. The recreated `LoginPage` shows empty fields because the text fields are uncontrolled, while the provider still reports a valid form and can submit the old credentials again.

## Chosen approach

Reset the login form provider when the login page is created and bind the fields to text controllers that stay in sync with provider state.

- Add a `reset()` method to `LoginFormController`.
- Call that reset when `LoginPage` is initialized.
- Use text controllers on the page so visible field contents and provider state cannot drift apart.

## Scope

- `lib/features/auth/presentation/providers/login_form_provider.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `test/auth/login_page_loading_test.dart`

## Behavioral rules

- Returning to the login page should clear the remembered username and password.
- `Sign In` should be disabled until the user types both fields again.
- Tapping `Sign In` on a freshly returned login page must not reuse old credentials.

## Non-goals

- Changing logout routing
- Changing login validation rules
- Changing token/session persistence
