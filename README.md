# Putaway App (Mock RBAC)

Zone-based warehouse tasks with Worker/Supervisor roles, running fully on mock data until the API is ready.

## Quick start

```bash
flutter pub get
flutter run
```

## Mock login

- **Supervisor**: phone `9990000000`, any PIN (mock). No fixed zone; pick a zone in the supervisor home.
- **Worker**: phone `1110000001`, any PIN (mock). Zone `Z01`.

## Roles & permissions

- **Worker**
  - Sees tasks for their zone only.
  - Can **claim** available tasks in their zone.
  - Can **complete** their active tasks.
- **Supervisor**
  - Can view tasks per selected zone.
  - Can **create** new tasks assigned to a zone (unassigned to workers).
  - Tasks created are claimable by any worker in that zone.

## Task model (mock)

- Fields: `id`, `type (receive/move/return/adjustment)`, `itemId`, `itemName`, `fromLocation?`, `toLocation?`, `quantity`, `assignedTo?`, `status (pending/inProgress/completed)`, `createdBy`, `zone`, `createdAt?`.
- Mock repository stores tasks per zone in-memory; create/claim/complete mutate state.

## UI overview

- **Worker Home**: two lists – *Available Tasks* (claim) and *My Active Tasks* (complete). Text styled for readability.
- **Supervisor Home**: zone selector, list of zone tasks, FAB opens create-task sheet (type, item name, quantity, from/to optional, zone). Creates unassigned zone tasks.
- **Account**: shows role/zone, language toggle, copy phone, change password placeholder, logout.

## Navigation

- Main scaffold bottom tabs: Home (role-aware: worker vs supervisor) and Account.
- RoleGuard widget exists for protecting supervisor-only screens if needed.

## Notes

- Entirely mock-backed; swap `TaskRepositoryMock` with real impl when API is ready.
