# Android Force Update Design

**Date:** 2026-03-26

## Goal

Add an Android-only force-update flow that reads a GitHub release-hosted `version.json`,
compares it with the installed app version, and blocks outdated builds with an
update screen that sends workers to the published GitHub release.

## Scope

- Applies only on Android.
- Reads `version.json` from a GitHub release asset URL.
- Runs on app startup and when the app resumes.
- Blocks app usage only when the installed version is lower than
  `minSupportedVersion`.
- Creates the initial `version.json` file for the current GitHub release.

## Decision

Use a release-hosted `version.json` asset instead of the GitHub releases API.

- It avoids API parsing and rate-limit issues.
- It gives the app one stable version file URL and one stable APK URL per
  release.
- It keeps the app logic focused on comparing versions and opening a single
  release URL.

## Architecture

- Add a small app-update domain/data layer that fetches `version.json` from the
  repo raw URL.
- Read the installed app version using `package_info_plus`.
- Compare the installed Android version with:
  - `latestVersion`
  - `minSupportedVersion`
- Store the result in an app-level controller that the root app widget can
  observe.
- When the installed version is below `minSupportedVersion`, render a blocking
  update screen instead of the normal routed app content.
- Tapping the update action opens the GitHub release URL from the JSON.

## JSON Contract

The remote file is published as a GitHub release asset and uses this shape:

```json
{
  "latestVersion": "1.2.1",
  "minSupportedVersion": "1.2.1",
  "downloadUrl": "https://github.com/osmsn637-tech/osman-ahmed/releases/download/putaway/putaway_app.apk",
  "releaseNotes": "Force update to the latest Android build."
}
```

- `latestVersion` is the newest available Android version.
- `minSupportedVersion` is the minimum version allowed to keep using the app.
- `downloadUrl` points to the GitHub release page.
- `releaseNotes` is optional copy shown on the blocking screen.

## Runtime Behavior

- Run the update check during app startup after Flutter binding initialization.
- Re-run the check when the app returns to the foreground.
- Only apply the force-update rule on Android.
- If the installed version is supported, continue to the normal routed app flow.
- If the installed version is too old, show a blocking full-screen update UI
  with:
  - current version
  - required version
  - release notes, when present
  - `Update App` action

## Error Handling

- If fetching `version.json` fails, the JSON is invalid, or the version strings
  cannot be parsed, fail open and allow the app to continue.
- If `downloadUrl` is missing or invalid, keep the blocking UI but disable the
  action with a helpful fallback message.
- Ignore the entire update flow on non-Android platforms.

## Testing

- Version comparison handles older, equal, and newer versions correctly.
- Android-only logic does not block other platforms.
- Network or JSON failures fail open.
- Root app renders the blocking update screen when force update is active.
- Resume lifecycle triggers another update check.
