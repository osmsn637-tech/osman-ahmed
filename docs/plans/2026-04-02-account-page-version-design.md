# Account Page Version Design

**Date:** 2026-04-02

## Goal

Show the installed app version at the bottom of the account page.

## Recommended Approach

Reuse the existing installed app version runtime service that already powers the app update flow. The account page should load the version asynchronously and render a muted footer string using the same display pattern already used on the login page: `v<version>`, falling back to `v--` until the lookup completes or if it fails.

## UI

Add a small centered footer below the existing action panel inside the account page scroll content so it appears at the bottom of the page content without affecting the current card layout.

## Error Handling

If version lookup fails or the provider is unavailable, keep the footer visible with the fallback value `v--`.

## Testing

Add a widget test that injects a fake installed-version provider, pumps the account page, and verifies the footer updates to the expected version string.
