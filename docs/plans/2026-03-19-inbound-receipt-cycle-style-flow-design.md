# Inbound Receipt Cycle-Style Flow Design

**Goal:** Replace the inbound `Receive` shortcut with a dedicated inbound receipt flow that mirrors cycle count interaction patterns while keeping inbound-specific labels and quantity behavior.

**Architecture:** Keep the flow inside `features/inbound` and route PO scans to a new `/inbound/receipt/:id` page. The receipt page owns a two-page internal state: a list page for the scanned PO and a detail page for a selected receipt item. Page transitions reuse the scan-first vs tap-first distinction from cycle count, but inbound quantity entry is unlocked immediately when the item is opened by scan.

**Tech Stack:** Flutter, Provider, GoRouter, existing inbound repository/data source stack, widget tests with fake repositories.

---

## UX

The inbound home `Receive` action opens the scan dialog, scans a PO, calls the inbound receipt scan endpoint, and navigates to a dedicated receipt page instead of the legacy `/receive` route.

The receipt page behaves like cycle count page 1:

- title and copy use `Receive` instead of `Cycle Count`
- the scanned PO is shown where cycle count shows the location
- the page lists receipt products with barcode and receipt quantity
- item rows do not show `Pending`; they show the expected receipt quantity
- scanning an item barcode on this page opens the matching item detail page in scan-open mode
- tapping an item row opens the same item detail page in manual-open mode

The item detail page behaves like cycle count page 2 with inbound-specific gating:

- if the item was opened by scan, quantity is enabled immediately
- if the item was opened by tapping, quantity stays locked until that exact item barcode is scanned on the detail page
- once quantity is confirmed, the page returns to the receipt list and the line shows the entered received quantity

## State Model

The page needs receipt-specific state rather than reusing worker task state:

- loaded receipt entity
- `selectedItemId`
- `openedByScan`
- detail barcode validated flag
- per-item received quantities keyed by receipt item id

## Data Model

Add dedicated inbound receipt entities for:

- scanned receipt result
- receipt detail with PO, status, and item lines
- receipt item line with id, name, barcode, and receipt quantity

Keep the existing legacy inbound document entities untouched so this flow does not collide with older create-document screens.

## Error Handling

- invalid or empty PO scan shows the existing snackbar error path
- unknown item scan on the receipt page shows a receipt-specific validation message and stays on page 1
- failed receipt load/start/item-confirm calls show a snackbar or inline message and leave current state intact

## Testing

Widget coverage should lock:

- inbound home receive scans route to `/inbound/receipt/:id`
- receipt page shows `Receive`, the scanned PO, and receipt quantities
- tapping an item opens detail with quantity locked until barcode scan
- scanning an item from the list opens detail with quantity enabled immediately
- confirming quantity returns to the list and updates that line's received quantity
