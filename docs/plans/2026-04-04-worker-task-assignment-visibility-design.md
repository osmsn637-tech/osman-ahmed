# Worker Task Assignment Visibility Design

## Goal

Hide tasks that are assigned to a different worker from the worker dashboard everywhere on the page, and show a clear status label on every visible task card.

## Chosen Approach

Apply the visibility rule in the worker dashboard controller after tasks are loaded:

- Keep tasks whose `assignedTo` value is empty.
- Keep tasks whose `assignedTo` matches the signed-in worker.
- Hide tasks assigned to any other worker from both current and completed sections.
- Recalculate overview counts from the filtered task set.
- Add a status pill to each visible task card for `Pending`, `In Progress`, or `Completed`.

## Why This Approach

- It keeps the worker-specific visibility rule local to the worker dashboard instead of changing shared repository behavior for other consumers.
- It ensures the task list, completed section, and overview counts all agree.
- It lets us improve the card UI without changing task-start or task-complete behavior.

## Verification

- Add widget coverage proving tasks assigned to another worker do not appear on the dashboard.
- Add widget coverage proving visible cards show their status text.
- Run related worker home widget tests and analyzer on touched dashboard files.
