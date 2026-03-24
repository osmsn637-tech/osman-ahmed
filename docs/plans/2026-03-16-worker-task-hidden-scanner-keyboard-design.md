# Worker Task Hidden Scanner Keyboard Design

## Goal

Stop the Android soft keyboard from opening when a worker opens a task, while keeping scanner capture fields auto-focused and scan-ready.

## Root Cause

`WorkerTaskDetailsPage` restores focus to hidden scanner `TextField`s after the page mounts. Those fields currently use `TextInputType.visiblePassword`, which still allows the soft keyboard to open when focus is requested.

## Chosen Approach

Keep the current focus-restoration behavior and change the hidden scanner fields to `TextInputType.none`.

## Why

- It preserves the existing scan-ready workflow.
- It matches the working scanner dialog pattern already used elsewhere in the app.
- It avoids brittle keyboard-hiding workarounds and does not require removing focus management.
