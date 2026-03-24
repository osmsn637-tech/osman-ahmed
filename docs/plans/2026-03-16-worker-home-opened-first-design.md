# Worker Home Opened Tasks First Design

**Date:** 2026-03-16

## Goal

Make the worker homepage show already opened tasks at the beginning of the main task list.

## Decision

Sort the homepage task list locally so tasks in progress and assigned to the current worker render before pending unassigned tasks.

## Scope

In scope:
- worker homepage task ordering
- widget coverage for opened-task-first rendering

Out of scope:
- controller state ordering for other screens
- repository ordering
- completed tasks section behavior

## Ordering Rule

1. Tasks with `status == TaskStatus.inProgress` and `assignedTo == current worker id` come first.
2. Pending unassigned tasks follow.
3. Any remaining non-completed tasks stay after those groups in stable order.

## Testing Intent

- Seed one opened task assigned to the current worker and one pending task.
- Verify the opened task card appears before the pending task card on the homepage.
