# Lookup Scan Dialog Refresh Design

**Date:** 2026-03-14

## Goal

Restyle the shared lookup scan popup so it feels cleaner and more intentional while keeping the current centered-dialog flow and scanner behavior.

## Decision

Keep the popup centered and use a compact scanner-first `Dialog` shell.

## Visual Direction

- Rounded centered card with a softer shadow and tighter spacing.
- Compact hierarchy:
  - small icon badge
  - title row with close action
  - barcode field
  - manual entry toggle
- Remove footer buttons completely.
- Use the existing app theme colors and avoid introducing a conflicting visual language.

## Interaction Rules

- Hardware scanner behavior stays unchanged.
- Manual entry remains available below the field.
- Switching to manual entry must not open the soft keyboard automatically.
- Close remains explicit through the `X`.
- Submission happens only from scanner auto-detect, keyboard search action, or field search icon.

## Accessibility

- Minimum comfortable tap targets for close, manual entry, and footer buttons.
- Strong text contrast and visible input focus.
- No heavy motion or layout jumps.

## Testing

- Add a widget test proving the dialog has no footer actions and keeps the compact manual-entry layout.
- Keep the scanner-input behavior test intact.
