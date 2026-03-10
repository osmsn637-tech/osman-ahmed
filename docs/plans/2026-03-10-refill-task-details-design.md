# Refill Task Details Redesign Design

**Date:** 2026-03-10

## Goal

Redesign the worker experience for `refill` tasks so the worker follows a clear warehouse flow:

1. Open the refill task
2. Load item route data immediately from the lookup API
3. Validate the item barcode in bulk
4. Move to a second screen
5. Validate the shelf location
6. Enter quantity manually
7. Complete the task

## Scope

This redesign applies only to `refill` tasks in the worker task details flow.

Out of scope:
- Other task types
- Worker home list card redesign
- Backend API changes

## Problem

The refill task API does not provide the route locations needed for the worker flow. The worker still needs a guided experience that shows:

- the item they are moving
- the bulk source location
- the shelf destination location
- the quantity to move

Those locations must come from the existing item lookup API, using the task barcode.

## Key Constraint

Refill route data must be fetched immediately when the refill task opens.

The task payload alone is not enough because the bulk and shelf locations are not reliably present in the task API.

## User Flow

1. Worker opens a refill task.
2. The app immediately calls the item lookup API using the task barcode.
3. While loading, the page shows a loading state.
4. If lookup succeeds, the worker sees Refill Screen 1.
5. Refill Screen 1 shows:
   - item image
   - item name
   - barcode
   - `From Bulk Location`
   - barcode validation input
6. After successful barcode validation, navigate to Refill Screen 2.
7. Refill Screen 2 shows:
   - `To Shelf Location`
   - shelf location validation input
   - manual quantity field
8. After shelf validation passes and quantity is valid, the worker can complete the task.

## Screen Design

### Screen 1: Bulk Confirmation

Purpose: confirm the worker has the correct item at bulk.

Show only:
- item image
- item name
- barcode
- source bulk location from lookup
- item barcode scan/entry field

Behavior:
- barcode field is active when lookup data is loaded
- matching barcode marks step complete
- success moves the worker to the second screen

### Screen 2: Shelf Confirmation

Purpose: confirm the destination shelf and collect quantity.

Show only:
- shelf destination from lookup
- location scan/entry field
- manual quantity input
- completion action

Behavior:
- location must validate against the lookup shelf location
- quantity must be manually entered
- quantity must be greater than zero
- quantity must not exceed the task quantity

## Data Flow

### Lookup Source

On refill-task open:
- use the task barcode
- call the same lookup API used elsewhere in the app

### Location Resolution

Use lookup results to identify:
- bulk location for screen 1
- shelf location for screen 2

The page should derive those from the lookup response rather than trusting `task.fromLocation` and `task.toLocation`.

## Error Handling

If lookup fails:
- show a blocking error state
- explain that route data could not be loaded
- disable the workflow
- offer retry

If the task has no barcode:
- show a blocking error state
- do not allow the refill flow to continue

If barcode validation fails:
- show mismatch feedback
- remain on screen 1

If shelf validation fails:
- show mismatch feedback
- keep completion disabled

If quantity is invalid:
- show clear validation feedback
- keep completion disabled

## Behavior Rules

- Only refill tasks use this 2-screen flow
- Lookup happens immediately on open
- Barcode validation must succeed before screen 2
- Shelf validation must succeed before completion
- Quantity is manual only
- Quantity cannot exceed task quantity
- Non-refill task flows remain unchanged

## Testing Intent

The redesign should be covered with focused tests that verify:
- refill task opens with lookup loading behavior
- lookup success populates bulk and shelf locations
- barcode validation advances to screen 2
- shelf validation and manual quantity gate completion
- lookup failure blocks the workflow
- non-refill task behavior stays unchanged
