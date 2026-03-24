# Cycle Count Empty Location And Barcode Gate Design

**Date:** 2026-03-16

## Goal

Keep the expected cycle count shelf visible for reference, but require the worker to scan or manually type the location, and prevent quantity entry until the item barcode is validated.

## Decision

Keep the change inside `WorkerTaskDetailsPage`. The cycle count location reference row will still show the expected shelf, but the actual validation input will start empty. On the cycle count item detail page, quantity entry remains locked until barcode validation succeeds.

## Scope

In scope:
- cycle count location input initialization
- cycle count item detail quantity enablement
- widget coverage for both behaviors

Out of scope:
- receive, refill, return, or generic task flows
- repository/controller changes
- changing the displayed reference shelf value

## Behavior Rule

1. Cycle count pages still display the expected location as read-only reference text.
2. The cycle count location validation input starts empty even when `toLocation` exists.
3. The worker must scan or manually type the cycle count location before validation can pass.
4. On the cycle count detail page, the quantity field stays disabled until the item barcode has been validated.

## Testing Intent

- Verify a cycle count task with `toLocation` still shows the shelf as reference but keeps the hidden/manual location input empty on first load.
- Verify the cycle count detail quantity field is disabled before barcode validation and enabled after the correct barcode is scanned or typed.
