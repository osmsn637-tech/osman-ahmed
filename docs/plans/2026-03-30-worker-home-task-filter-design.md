# Worker Home Task Filter Design

## Goal

Add a one-row task-type filter to the worker homepage that filters only the current task list using the same task names and colors already shown on task badges.

## Chosen Approach

Render a horizontal filter row directly above the current task cards:

- An `ALL` pill clears the filter.
- One pill is shown for each task type currently present in the current-task queue.
- Each pill reuses the task type label logic and task type color already used on the task cards.
- Completed tasks remain unfiltered.

## Why This Approach

- It keeps the filter visually consistent with the existing task cards.
- It avoids wasting space on task types that are not present.
- It matches the “one row” requirement with a simple horizontal scroll container.

## Verification

- Add widget coverage for:
  - rendering the filter row in one horizontal line
  - filtering only current tasks when a type is selected
  - leaving completed tasks unchanged
