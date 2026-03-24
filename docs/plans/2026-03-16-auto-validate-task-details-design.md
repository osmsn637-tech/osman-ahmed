# Auto Validate Task Details Design

Date: 2026-03-16

## Goal

Remove explicit validation buttons from the worker task details flows and validate automatically when the user scans or types input, while advancing to the next step automatically after successful validation.

## Problem

The current task details flows require explicit `Validate Product` and `Validate Location` button taps after the scanner or manual entry has already filled the field. That forces duplicate interaction, encourages scanning the same value twice, and slows the receive/refill/cycle-count flows that are already structured as sequential steps.

## Chosen approach

Use automatic validation triggered by field changes once a non-empty scan/input value is present.

- Hide the visible validation buttons across task details flows.
- Reuse the existing local and remote validation rules instead of changing the validation contract.
- Guard against duplicate validation runs when the same value is already being processed or was already accepted.
- Auto-advance receive/refill/cycle-count flows immediately after successful validation instead of waiting for a second button press.

## Scope

- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

## Behavioral rules

- Product barcode validation should happen automatically when the product field changes to a non-empty value.
- Location validation should happen automatically when the location field changes to a non-empty value and the task is ready for location validation.
- Remote location validation should still be called when required, but only once per entered value unless the value changes.
- Successful receive/refill validation should move the user to the next page automatically.
- Generic task flows should validate without showing a separate validate button.
- Existing mismatch and backend error messages should remain visible.

## Non-goals

- Changing return line-item validation buttons
- Changing adjustment scan actions
- Changing the completion contract with the repository
