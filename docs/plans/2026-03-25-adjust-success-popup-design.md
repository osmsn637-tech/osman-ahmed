# Adjust Success Popup Design

## Goal

Show a success popup after a standalone item adjustment succeeds so the worker gets explicit feedback before the app returns to the previous screen or home.

## Scope

- Only the standalone item lookup adjust flow is affected.
- The dashboard adjustment-task flow is unchanged.
- Existing submit behavior and payloads stay the same.

## Interaction

1. Worker submits an item adjustment from the item lookup result page in adjust mode.
2. When the adjustment succeeds, the page shows a modal success dialog.
3. The dialog contains a success title, a short confirmation message, and one confirm button.
4. After the worker taps confirm, the dialog closes and the page follows the existing navigation behavior:
   - pop when possible
   - otherwise go to `/home`

## Testing

- Add a widget test proving the success dialog appears after submit.
- Verify the page does not navigate away before confirm is tapped.
- Verify tapping confirm performs the existing back/home navigation.
