# Lookup Popup Action Row Design

**Date:** 2026-03-16

## Goal

Polish the shared lookup popup and fix the keypad action-row overflow so the `Delete` and `Confirm` labels fit cleanly.

## Decision

Keep the dark-blue dialog card and the fixed `3x3` digit grid, but replace the bottom keypad row with label-fitting action pills instead of forcing all action cells into equal widths.

## Visual Direction

- Preserve the dark-blue card shell.
- Improve hierarchy with cleaner spacing and slightly softer inset surfaces.
- Keep digit buttons consistent, but let action pills size to their labels.
- Use a stronger white-pill treatment for `Delete` and `Confirm`.

## Layout

- Keep digits `1-9` in the stable three-column grid.
- Keep `0` in the action row.
- Make `Delete`, `0`, and `Confirm` fit their content instead of stretching into equal-width cells.
- Preserve small-screen safety so labels do not overflow in narrow test widths.

## Testing Intent

- Verify the keypad still opens and submits on confirm.
- Verify the action labels remain visible on a narrow-width surface.
- Verify the popup produces no layout overflow during that narrow-width scenario.
