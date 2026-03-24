# Return Auto Scan Design

Date: 2026-03-16

## Goal

Let return-task barcode validation work like receive: the user scans directly on the validation page without tapping a specific item row first.

## Problem

The current return validation page requires tapping a row-level scan button before each item barcode scan. That slows the flow and makes return behave differently from receive, even though the user already knows the scanner should just validate the next matching item.

## Chosen approach

Add a scanner-ready capture field to the return validation page and auto-match the scanned barcode against any unvalidated return line.

- Keep the list visible so the user can see which rows are already validated.
- Match the scanned barcode to the first unvalidated row with the same barcode.
- Mark only that row validated.
- Leave the second return page unchanged for return location and quantity.

## Scope

- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

## Behavioral rules

- The user should not need to tap a row before scanning a return barcode.
- A matching scan should validate one unvalidated row automatically.
- A duplicate scan of an already validated item should not validate another row unless another matching unvalidated row exists.
- A non-matching scan should keep the user on the validation page and surface an error.

## Non-goals

- Changing the return execution page
- Changing location scan behavior on page two
- Changing completion rules
