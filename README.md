# QEU Putaway

Flutter mobile client for warehouse operations. The app is API-backed and
centered on scanner-first flows for worker task execution, inbound receiving,
item lookup, stock adjustment, and account management.

## Full documentation

The full app documentation now lives in:

- `docs/app-documentation.md`

That document covers:

- architecture and runtime boot flow
- routes and role-aware navigation
- worker, inbound, lookup, adjustment, and account flows
- localization, training entry points, and Android force updates
- production vs development API environments
- the internal persisted dev-mode toggle
- development, testing, and maintenance guidance

## Quick start

```bash
flutter pub get
flutter run
```

## Common checks

```bash
flutter test
dart analyze
```
