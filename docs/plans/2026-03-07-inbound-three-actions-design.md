# Inbound Home Simplification Design (2026-03-07)

## Goal
Simplify the inbound role home screen to only expose three actions as buttons until full receipt flows are implemented.

## Scope
- Keep the current inbound visual style direction (app bar, gradient background, button treatment).
- Remove inbound document overview metrics, status sections, and document cards from the inbound home UI.
- Show exactly three action buttons:
  1. `Create Receipt`
  2. `Receive Pending Receipt`
  3. `Lookup from Putaway`

## Behavior
- `Create Receipt`: show placeholder snackbar (existing TODO behavior retained).
- `Receive Pending Receipt`: show placeholder snackbar (existing TODO behavior retained).
- `Lookup from Putaway`: use the same lookup scan flow used by worker:
  - open scan dialog
  - if barcode is provided, navigate to `/item-lookup/result/:barcode`

## Non-Goals
- No changes to inbound repository/controller data APIs.
- No implementation of receipt creation/receiving workflows yet.
- No role or routing model changes outside inbound home content.

## Testing
- Add/update widget test coverage to assert inbound home shows exactly these three actions.
- Assert legacy inbound card action labels are not rendered.
