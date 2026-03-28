# Secret Dev Mode Design

## Goal

Add a hidden developer mode that is triggered from the account page by tapping the zone row five times, entering the PIN `564238`, and switching the app between the production API and the development API. The selected mode must persist across future app launches and the UI must visibly indicate when dev mode is active.

## Current State

- `AppConfig.load()` always returns the production API base URL.
- The provider tree is built once in `main.dart`, so changing the API requires rebuilding the app shell.
- Auth and user state are persisted through secure storage, which means environment switches can otherwise reuse production credentials against the dev API.
- The account page already renders the user zone in a dedicated info row, which is a natural hidden trigger point.

## Recommended Approach

Use a persisted app-environment controller as the bootstrap source of truth.

1. Store the selected environment in secure storage.
2. Resolve `AppConfig` from that environment during startup.
3. Wrap the app in a lightweight bootstrap widget that can rebuild the provider tree when the environment changes.
4. Add a hidden five-tap zone trigger that opens a PIN dialog and toggles the environment on the correct PIN.
5. Clear persisted auth/session during the switch and show a visible `DEV` badge while the development API is active.

This keeps the environment switch centralized, testable, and durable across launches.

## Architecture

### Environment Model

- Introduce an `AppEnvironment` enum or equivalent with `production` and `development`.
- Derive the base URL from the selected environment:
  - production: `https://api.qeu.info`
  - development: `https://api.qeu.app`
- Keep version metadata and other shared config fields unchanged.

### Persistence

- Reuse secure storage with a separate key for the selected environment.
- Default to production when no stored value exists or the stored value is invalid.

### Bootstrap And Restart Behavior

- Replace the one-time startup config load in `main.dart` with a bootstrap widget/controller.
- The bootstrap loads the persisted environment, resolves an `AppConfig`, and builds `MultiProvider(providers: appProviders(config), child: PutawayApp(...))`.
- When the environment toggles, the bootstrap:
  - persists the new environment
  - clears auth/session state
  - rebuilds the provider tree with the new API base URL

### Account Page Secret Flow

- Make the zone row tappable without changing the visible design.
- Count taps locally; on the fifth tap, reset the counter and show a PIN dialog.
- If the user enters `564238`, toggle the environment and show confirmation feedback.
- If the PIN is wrong, keep the current environment and show an error.

### Dev Indicator

- Add a compact global `DEV` ribbon overlay in the app shell when the development environment is active.
- Style it as a small diagonal debug-style stripe in the physical top-left corner.
- Use a yellow warning/debug color so it stands apart from production without feeling like an error state.
- Keep the indicator outside routed pages so it remains visible everywhere.

## Error Handling

- Invalid or missing stored environment falls back to production.
- Wrong PIN never changes the environment.
- If persistence fails during toggle, keep the current environment and show an error message instead of partially switching.

## Testing Strategy

Follow TDD:

1. Add failing tests for config/environment persistence behavior.
2. Add failing widget tests for the hidden five-tap flow and correct/wrong PIN handling.
3. Add failing app-shell tests for the `DEV` badge and environment-dependent rebuild behavior.
4. Implement the minimum production code to pass.

## Success Criteria

- Five taps on the zone row opens a PIN prompt.
- Entering `564238` toggles between prod and dev using the same hidden flow.
- The app uses `https://api.qeu.app` in dev mode and `https://api.qeu.info` in prod mode.
- The selected mode persists across future launches.
- The app visibly shows `DEV` while dev mode is active.
- Auth/session data is cleared when switching environments.
