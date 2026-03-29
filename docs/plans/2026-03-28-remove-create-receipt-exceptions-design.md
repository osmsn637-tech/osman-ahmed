# Remove Create Receipt And Exceptions Design

## Goal

Remove the unused `Create Receipt` and `Exceptions` user-facing flows so they no longer appear in routing, docs, or localization, while keeping the deeper dashboard exception data plumbing unchanged for now.

## Scope

- Delete the unused pages for create inbound and exceptions.
- Delete the orphaned `MorePage` that still referenced exceptions.
- Remove the corresponding top-level routes from the router.
- Remove now-dead localization keys and stale documentation references.
- Keep repository/domain/dashboard summary exception internals intact.

## Approach Options

### Option 1: User-facing removal only

Delete the screens, routes, docs, and strings, but leave deeper exception repository/state contracts in place. This is the smallest safe change and matches the requested scope.

### Option 2: Full exception teardown

Also remove exception entities, repository methods, use cases, state fields, and related backend fetch logic. This is cleaner eventually, but it is a broader dashboard refactor than requested.

## Chosen Approach

Use option 1.

Rationale:

- The removed flows are already effectively dead or orphaned.
- The user asked specifically to delete the features, not to refactor dashboard internals.
- Keeping the domain plumbing avoids risk in unrelated dashboard code paths.

## Validation

- Add a router test that proves `/inbound/create`, `/exceptions-tab`, and `/exceptions` are absent.
- Run that test first and confirm it fails before changing production code.
- Run the targeted test again after the removal.
- Run the full test suite and analyzer before closing the task.
