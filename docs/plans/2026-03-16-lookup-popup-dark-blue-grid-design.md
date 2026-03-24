# Lookup Popup Dark Blue Grid Design

**Date:** 2026-03-16

## Goal

Adjust the shared lookup popup so the keypad is a true `3x3` digit grid and the entire card uses a dark-blue visual treatment.

## Decision

Keep the hidden scanner-input behavior and confirm-based manual keypad flow, but restyle the whole dialog card into a dark-blue surface and replace the wrapping digit layout with a fixed three-column grid.

## Visual Direction

- Make the full popup card dark blue using `AppTheme.primary`.
- Use lighter blue inset surfaces for the scanner status panel and keypad display.
- Use white or very light blue text and icons for contrast.
- Keep `Confirm` as the strongest action and `Cancel` as the lighter secondary action.

## Layout

- Preserve the hidden autofocus scanner field.
- Replace the keypad `Wrap` with a true three-column digit grid so `1-9` always render in three rows.
- Keep the bottom action row as `Del`, `0`, and `Confirm`.
- Keep the popup scroll-safe for smaller test and mobile heights.

## Testing Intent

- Verify the popup card surface is dark blue.
- Verify the manual keypad digits render in a true three-column layout.
- Keep the existing confirm-based manual submit behavior intact.
