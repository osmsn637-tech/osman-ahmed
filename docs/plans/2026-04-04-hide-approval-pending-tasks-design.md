# Hide Approval-Pending Tasks Design

**Date:** 2026-04-04

## Goal

Hide tasks that are effectively completed but still marked with an approval-pending backend status so they do not appear anywhere in the worker task experience.

## Scope

- Filter these tasks out from the worker task data before the UI splits them into current and completed sections.
- Apply the rule everywhere the worker task list is sourced from the dashboard repository.
- Keep normal pending, in-progress, and completed task behavior unchanged.

## Design

- Detect raw backend status values that represent an approval-pending post-completion state.
- Keep the filtering centralized in the dashboard task repository so counts, lists, and resume behavior all see the same filtered task set.
- Do not add UI-specific hiding rules in the home page.
- Add regression coverage in repository tests to prove approval-pending completed tasks are excluded from the returned task collection.

## Success Criteria

- Approval-pending completed tasks do not appear in current tasks.
- Approval-pending completed tasks do not appear in completed tasks.
- Existing worker task flows continue to parse and display normal statuses correctly.
