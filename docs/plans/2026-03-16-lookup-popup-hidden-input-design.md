# Lookup Popup Hidden Input Design

**Date:** 2026-03-16

## Goal

Redesign the shared lookup popup so scanning always flows through a hidden autofocus input, searches trigger automatically from scanner input changes, and manual typing uses an in-place numeric `3x3` keypad with an explicit confirm action.

## Scope

In scope:
- `showItemLookupScanDialog()` shared popup behavior
- hidden scanner input focus and auto-search behavior
- in-place manual numeric keypad UI
- dark-blue visual treatment for the manual entry action and primary keypad actions

Out of scope:
- worker task detail hidden inputs
- item lookup result page behavior
- backend lookup APIs or barcode validation rules

## Decision

Keep one centered lookup dialog and move scanner capture to an always-mounted hidden `TextField`.

- Scanner input remains the primary mode and continues to auto-submit on terminator or short debounce.
- The visible text field is removed from the popup body.
- A dark-blue `Manual Type` button reveals an in-place numeric keypad instead of opening the software keyboard.
- Manual keypad entry waits for an explicit confirm button, then reuses the same lookup submission path as a scan.

## Interaction Model

1. User opens the lookup popup.
2. Hidden scanner input takes focus after the first frame.
3. Hardware scanner input updates the hidden field and auto-searches.
4. User can tap `Manual Type` to open the keypad panel.
5. User enters digits on the `3x3` keypad plus `0`.
6. User taps `Confirm` to submit the manual value.
7. Cancelling or closing the keypad restores focus to the hidden scanner input.

## Visual Direction

- Preserve the compact centered dialog shell.
- Replace the visible input row with a scanner status panel and optional keypad panel.
- Use `AppTheme.primary` dark blue for the manual-entry CTA, keypad confirm button, and keypad accents.
- Keep high contrast against the light app surface and preserve clear close affordance.

## Error Handling

- Empty scanner submissions continue to show the existing barcode validation error.
- Empty manual keypad values keep `Confirm` disabled.
- Invalid values reuse the existing dialog error message area.
- Closing the dialog still returns `null`.

## Testing Intent

- Verify the popup opens with the hidden scan field mounted and focused.
- Verify scanner mode still suppresses `TextInput.show`.
- Verify the manual keypad is hidden by default and appears after tapping `Manual Type`.
- Verify manual entry requires `Confirm` before the dialog returns a value.
- Verify the visible text entry field no longer appears in the popup body.
