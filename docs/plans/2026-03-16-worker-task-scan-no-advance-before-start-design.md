# Worker Task Scan No Advance Before Start Design

**Date:** 2026-03-16

## Goal

When a worker opens a task but has not started it yet, scanning the correct product barcode should show a positive alert with `right product` and keep the worker on the first page.

## Decision

Keep the change local to the task details page. Product validation will continue to compare the scanned barcode against the task barcode, but receive and refill flows will only auto-advance after the task is effectively started.

## Scope

In scope:
- receive and refill product barcode validation on the task details page
- pending task behavior before `Start Task`
- widget coverage for the no-advance rule

Out of scope:
- repository or controller changes
- task start API behavior
- location validation behavior after the task is started

## Behavior Rule

1. If the task is still pending and has not been started locally, a correct product barcode shows `right product`.
2. In that pending state, the UI stays on page one and does not reveal the second-page location flow.
3. Once the task is started and the effective status becomes `inProgress`, the current auto-advance behavior stays unchanged.
4. Incorrect barcodes keep the existing mismatch behavior.

## Testing Intent

- Pump a pending receive task with a start action and a completion action.
- Scan the correct product barcode before tapping `Start Task`.
- Verify `right product` is shown.
- Verify the page-two location UI is still hidden.
- Verify the current started-task receive flow still advances after a correct scan.
