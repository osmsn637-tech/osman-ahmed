# Manual Barcode Keypad Design

Date: 2026-03-16

## Goal

Fix the manual barcode keypad so it always renders as a true 3x3 numeric grid and improve the visual design so it feels intentional and easier to use on touch devices.

## Problem

The current manual barcode keypad is built with a `Wrap`, so it can collapse into fewer columns when the dialog width is constrained. That produces an inconsistent 2-column or uneven keypad instead of a stable numeric pad. The visual design is also too plain for a primary scanning fallback interaction.

## Chosen approach

Replace the `Wrap`-based keypad with a fixed grid layout and restyle the dialog as a structured numeric-entry surface:

- Use a fixed 3-column grid for digits `1-9`
- Use a dedicated bottom row for `Delete`, `0`, and submit
- Improve spacing, hierarchy, and button styling for better touch use
- Keep existing keys and behavior so the rest of the screen logic stays unchanged

## Scope

- `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

## UX rules

- Numeric keys should always render in a strict 3x3 layout
- Touch targets should remain comfortably larger than 44x44
- The current typed value should be visually emphasized at the top
- Delete should be visually distinct from digit keys
- Submit should remain disabled until there is input

## Non-goals

- Changing manual location entry
- Changing barcode validation logic
- Changing the scanner flow outside the manual keypad dialog
