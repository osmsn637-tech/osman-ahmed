# Worker Task Visibility Design

**Date:** 2026-03-15

## Goal

Show all API-returned worker task categories in the worker queue using normalized app labels:

- `putaway` and `receiving` -> `RECEIVE`
- `restock` -> `REFILL`
- `return` -> `RETURN`

## Current Problem

Two issues combine to make the queue misleading:

- Some task types can be filtered out before render because zone derivation treats arbitrary numbered subtitles as zones.
- User-facing labels are built from `TaskType.name`, which produces values like `RETURNTASK` instead of `RETURN`.

## Decision

Keep the current task workflows and internal `TaskType` model, but tighten task visibility and display rules:

- Preserve normalized internal task types for workflow branching.
- Stop deriving zones from non-zone subtitles.
- Treat tasks with no derived zone as visible in the worker queue, since `/mobile/v1/worker/tasks` is already worker-scoped.
- Render task type labels from an explicit display mapping instead of enum names.

## Impact

### Repository

- Adjust unified task zone derivation so subtitle text only contributes when it contains a real zone code.
- Broaden requested-zone matching to keep API tasks whose zone cannot be derived.

### UI

- Replace `type.name.toUpperCase()` with a dedicated display-label helper.
- Use the helper in worker home badges and worker task details.

### Tests

- Add a repository test proving mixed `putaway`, `restock`, and `return` tasks all survive zone selection.
- Add widget assertions proving normalized labels show `RECEIVE`, `REFILL`, and `RETURN`.

## Verification

- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
