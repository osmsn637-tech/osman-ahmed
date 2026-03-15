# Mock Putaway Cycle Count And Return Design

**Date:** 2026-03-14

## Goal

Add mock worker task flows for `cycle count` and `return` so the team can design, demo, and refine the operational workflow before wiring real backend logic.

## Scope

This design applies to the worker dashboard queue and worker task details flow.

In scope:
- mock tasks in the worker queue
- worker detail workflows for `cycle count`
- worker detail workflows for `return`
- support for both single-item and full-shelf cycle count mocks

Out of scope:
- backend API changes
- manager dashboard UI
- supervisor workflow changes
- permanent inventory transaction models

## Worker Experience

The worker should see these as normal operational tasks.

Do not show:
- `Manager Request`
- manager identity
- source labels that expose how the task was created

The worker only sees the task type, item or location context, and the next action.

## Task Shapes

### Return Task

Purpose: process returned inventory back into the warehouse.

Mock worker flow:
1. Open task
2. View return item list on page 1
3. Validate each item line from the list
4. Tap `Return` to move to page 2
5. For each item line, scan the destination location and enter quantity
6. Complete when all item lines are processed

Expected task data:
- tote or container id
- return item lines

Each return item line includes:
- item name
- barcode
- quantity
- image
- destination location

### Cycle Count Task

Purpose: verify inventory accuracy for either a directed SKU count or an entire shelf.

Two mock modes:

#### Single-Item Count

Flow:
1. Open task
2. Scan shelf location
3. Scan item barcode
4. Enter counted quantity
5. Review variance
6. Complete

Expected task data:
- shelf location
- item name
- item barcode
- expected quantity

#### Full-Shelf Count

Flow:
1. Open task
2. Scan shelf location
3. Show expected SKU lines for the shelf
4. Enter counted quantity for each expected line
5. Optionally add unexpected item lines found on the shelf
6. Review variances
7. Complete

Expected task data:
- shelf location
- expected lines with sku, barcode, expected quantity
- optional unexpected lines added by worker

## UI Approach

Use the existing `WorkerTaskDetailsPage` as the entry point and branch the body by `TaskType`, the same way `receive` and `refill` already do.

Recommended implementation:
- keep task cards in the existing worker queue
- add richer mock metadata to tasks so the detail page can render the steps
- keep non-target task types unchanged

## Data Model Direction

Add lightweight mock workflow metadata to `TaskEntity` so mock tasks can describe:
- cycle count mode
- tote/container id
- return item lines
- cycle count expected lines
- unexpected lines entered during the mock flow

This avoids inventing new routes or overloading unrelated fields.

## Behavior Rules

- worker cards remain normal task cards
- no manager-origin labels appear anywhere in worker UI
- `cycle count` and `return` get guided multi-step flows
- `single-item cycle count` and `full-shelf cycle count` share the same task type with different mock metadata
- completion uses the current completion callback, passing quantity and location where applicable

## Testing Intent

Add focused widget coverage for:
- return flow renders a multi-item validation list on page 1
- return flow enables the `Return` action only after all item lines are validated
- return flow requires location scan and quantity entry for every item line on page 2
- single-item cycle count gates completion on location, item, and counted quantity
- full-shelf cycle count renders expected lines, allows unexpected lines, and enables completion only after review-ready input
- mock repository seeds these tasks so they appear in the worker queue
- existing receive, refill, and generic flows remain intact
