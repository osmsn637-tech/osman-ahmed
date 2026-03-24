# Adjustment Decrease Stepper Design

## Goal

Make the adjustment page behave the way the UI implies: in decrease mode, the `-` button should actually build a decrease.

## Root Cause

The adjustment editor stores a positive delta and currently treats the `+` button as "increase delta" for both modes. In decrease mode, that means the user has to press `+` to subtract stock, while the `-` button is disabled at zero.

## Chosen Approach

Keep the existing positive delta model, but make each button act relative to the selected mode.

## Behavior

- In `Decrease` mode:
  - `-` increases the decrease amount.
  - `+` reduces the decrease amount back toward zero.
- In `Increase` mode:
  - `+` increases the increase amount.
  - `-` reduces the increase amount back toward zero.

## Why

- It fixes the user-facing bug with minimal state changes.
- It preserves the existing preview and submit math.
- It keeps the mode chips meaningful instead of forcing users to learn reversed controls.
