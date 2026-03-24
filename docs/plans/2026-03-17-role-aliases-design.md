# Role Alias Mapping Design

## Goal

Make backend role aliases map to the app's existing canonical roles without duplicating routing logic across the UI.

## Approved Mapping

- `receiver` should behave as `inbound`
- `putaway operator` should behave as `worker`

## Approach

Keep the original backend role string on the user model, but add one normalization layer in the auth domain so the rest of the app can ask for the canonical role. Existing role checks, role-aware home selection, route guards, and account labels should use the canonical role instead of the raw backend string.

## Why This Approach

- Preserves the backend-provided role value for debugging or future API changes
- Avoids scattering alias checks across pages and widgets
- Minimizes regression risk because one normalization point drives all role-aware behavior

## Affected Areas

- Auth domain role helpers
- Role-aware home selection and guards
- Account page role labeling
- Targeted widget/domain tests for alias behavior
