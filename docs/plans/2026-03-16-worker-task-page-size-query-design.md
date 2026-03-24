# Worker Task Page Size Query Design

## Goal

Align the worker tasks API request with the backend contract by sending `page_size` instead of `limit`.

## Chosen Approach

Rename the request argument from `limit` to `pageSize` in `TaskRemoteDataSource.fetchMyTasks()` and send that value as the `page_size` query parameter.

## Why

- The backend is responding correctly when the request uses `page_size`.
- Keeping the change scoped to the worker task datasource avoids unrelated pagination churn.
- Renaming the Dart argument makes the client code match the API contract instead of preserving misleading terminology.

## Impact

- Worker task fetches will request the intended page size.
- Repository pagination logic remains unchanged because it already handles cursors.
- Tests need to cover the query parameter name to prevent regressions.
