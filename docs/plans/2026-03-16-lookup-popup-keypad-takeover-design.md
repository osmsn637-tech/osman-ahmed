# Lookup Popup Keypad Takeover Design

**Date:** 2026-03-16

## Goal

When the manual keypad opens, simplify the popup so the keypad becomes the only active content area.

## Decision

Hide the scan-status panel, the `Manual Type` button, and the bottom `Cancel` button whenever the keypad is open.

## Interaction

- Scan-first mode keeps the waiting/scan status panel and the `Manual Type` trigger visible.
- Opening the manual keypad removes the scan-mode chrome.
- The keypad keeps its own confirm action and close `X`.
- Returning from manual mode restores the scan-mode sections.

## Testing Intent

- Verify the scan-status panel is visible before manual mode and hidden during manual mode.
- Verify the `Manual Type` button is hidden during manual mode.
- Verify the bottom `Cancel` button is hidden during manual mode.
