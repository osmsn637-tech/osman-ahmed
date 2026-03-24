# Scanner-Friendly Task Capture Design

Date: 2026-03-16

## Goal

Restore real scanner input for cycle count and return flows without undoing the recent auto-validation and manual keypad improvements.

## Problem

Cycle count and return scans currently rely on scanner capture `TextField`s that were changed to fully hidden, zero-sized fields with `TextInputType.none`.

- Cycle count uses a hidden scan field on the task details page.
- Return uses the shared scan dialog, which now also hides the scan field completely.

Widget tests still pass because they inject text directly into the field, but many hardware wedge scanners stop sending text when the focused field is zero-sized or configured as `none`.

## Chosen approach

Keep the scanner fields visually unobtrusive, but make them scanner-friendly again:

- Restore a real editable capture surface for the shared scan dialog.
- Restore a real editable capture surface for cycle count and hidden validation fields used by scanner input.
- Keep focus management and soft-keyboard suppression so the IME does not pop up during scanning.
- Keep the manual keypad and auto-validation behavior unchanged.

## Scope

- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `lib/features/move/presentation/pages/item_lookup_scan_dialog.dart`
- `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- `test/features/move/presentation/pages/item_lookup_scan_dialog_test.dart`

## Behavioral rules

- A hardware scan in cycle count should still be captured immediately after location validation.
- A hardware scan in the return dialog should still be captured immediately after the dialog opens.
- Scanner capture fields may remain visually hidden from the layout, but they must not rely on the configuration that blocks real scanner text delivery.
- Manual entry and automatic validation should keep working as they do now.

## Non-goals

- Redesigning the return workflow
- Changing validation rules
- Changing completion behavior
