# Dashboard API-Only Tasks Design

**Date:** 2026-03-14

## Goal

Remove dashboard task placeholders and local task creation so the worker task list is sourced only from the API response.

## Current Problem

`TaskRepositoryImpl` currently does two things that bypass the API:

- Seeds local mock return and cycle-count tasks into the worker queue.
- Implements `createTask`, which allows local task creation through the dashboard repository contract.

That makes the worker queue diverge from backend state and leaves dead behavior paths in production code.

## Decision

Keep dashboard tasks API-backed only.

- `getTasksForZone` returns parsed remote tasks filtered by zone.
- Local repository state remains only for cached copies of real tasks and worker-side progress like claim/completion/cycle-count progress.
- Remove seeded mock-task generation from `TaskRepositoryImpl`.
- Remove `createTask` from the dashboard task repository contract and remove the event-routing use case that depends on it.

## Impact

### Repository

- Delete mock seeding helpers and mock-specific branches in claim, validate, and complete paths.
- Keep remote task parsing, cache hydration, and local state overlays for real tasks.

### Domain

- Remove `createTask` from `TaskRepository`.
- Remove `RouteTaskFromEventUseCase`, which no longer has a valid persistence path.

### Tests

- Repository tests should assert that empty API responses stay empty.
- Remove tests that expect seeded mock return/cycle-count tasks from `TaskRepositoryImpl`.
- Remove tests dedicated to `RouteTaskFromEventUseCase`.
- Leave `TaskRepositoryMock` available as a test-only fixture source for widget tests that explicitly opt into mock data.

## Risks

- Any code still depending on `createTask` will fail to compile until updated or removed.
- Tests that assumed default placeholder tasks will need explicit fixtures.

## Verification

- Targeted repository tests for remote parsing, claiming, validation, completion, and empty responses.
- Targeted dashboard tests to ensure no production path expects seeded local tasks.
