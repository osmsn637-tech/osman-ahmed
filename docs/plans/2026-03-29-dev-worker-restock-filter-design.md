# Dev Worker Restock Filter Design

## Goal

In development only, have the worker task API fetch default to `task_type=restock` so the app loads only restock tasks from the worker tasks endpoint.

## Chosen Approach

Apply the filter in `TaskRemoteDataSource.fetchMyTasks()` through a datasource-level default task type:

- Production keeps the current behavior and sends no implicit `task_type`.
- Development injects a default task type of `restock`.
- An explicit `taskType` argument still wins over the default so the datasource remains reusable.

## Why This Approach

- It changes the actual API request rather than filtering after fetch.
- It keeps the behavior close to the endpoint code that already owns `task_type`.
- It avoids touching repository mapping or UI logic.

## Verification

- Add datasource tests for:
  - development defaulting `task_type` to `restock`
  - production leaving `task_type` unset when no explicit type is provided
- Run the dashboard presentation test suite after wiring the provider.
