# Remaining API And Completion Audit

Date: 2026-03-15

This note captures what is still mock-backed, missing an API-backed implementation, or otherwise incomplete based on the current repository state.

## Still mock-backed at runtime

- Move, receive, and standalone stock adjustment still use `ItemRepositoryMock` through dependency injection in `lib/shared/providers/app_providers.dart`.
- Inbound still uses `InboundRepositoryMock` through dependency injection in `lib/shared/providers/app_providers.dart`.

## API endpoints that exist but are not fully wired

- Inventory move endpoint exists in `lib/core/constants/app_endpoints.dart` as `moveItems`, but the runtime app flow still resolves through the mock item repository.
- Inventory receive endpoint exists in `lib/core/constants/app_endpoints.dart` as `receiveItems`, but the runtime app flow still resolves through the mock item repository.
- Item stock endpoint exists in `lib/core/constants/app_endpoints.dart` as `itemStock`, but the standalone move and receive flows still rely on mock item/location data.
- Cycle count endpoints exist in `lib/core/constants/app_endpoints.dart` as `cycleCount` and `locationItems`, but the real repository methods are not implemented yet.

## Incomplete repository work

- `lib/features/move/data/repositories/item_repository_impl.dart`
  - `fetchLocationItems` is marked TODO.
  - `submitCycleCount` is marked TODO.
- `lib/features/cycle/domain/entities/submit_cycle_count_params.dart`
  - Uses `List<dynamic>` for `items` and is marked TODO to replace with a concrete item model.

## Areas already API-backed

- Login is API-backed through `AuthRemoteDataSourceImpl` and `AuthRepositoryImpl`.
- Worker task fetch/start/scan/complete flows are API-backed through `TaskRemoteDataSource` and `TaskRepositoryImpl`.
- Worker adjustment task scan/count/finish flows are API-backed through `TaskRemoteDataSource` and `TaskRepositoryImpl`.
- Item lookup by barcode is API-backed through `ItemRemoteDataSourceImpl`.

## UI or copy that still signals incomplete work

- Inbound localization strings still contain explicit TODO copy in `l10n/app_en.arb`:
  - `inboundReceiveDialogTodo`
  - `inboundViewTodo`
- The README is stale and still describes the app as fully mock-backed even though auth, dashboard task flows, and lookup now have API wiring.

## Repo state note

- The worktree currently contains many in-progress dashboard, adjustment, cycle-count, and test changes that are separate from this audit note.
