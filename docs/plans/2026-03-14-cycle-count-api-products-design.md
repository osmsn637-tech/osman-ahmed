# Cycle Count API Products Parsing Design

## Summary

Update cycle count task parsing so real API payloads with `task_type: cycle_count` and a `products` array feed the worker cycle count UI directly.

The `products` array becomes the authoritative source for countable items. Any product with `quantity <= 0` is hidden from the worker list. The existing two-page cycle count UI continues to consume normalized cycle count items through `TaskEntity`, so this change stays concentrated in parsing and entity normalization.

## Payload Match

Given payloads like:

```json
{
  "task_type": "cycle_count",
  "products": [
    {
      "product_id": "1802",
      "name": "Product A",
      "barcode": "5000396014822",
      "image": "http://img.qeu.app/products/5000396014822/5000396014822_image.webp",
      "quantity": 21
    }
  ],
  "item_count": 8
}
```

the parser should:

- keep only products with `quantity > 0`
- map them into cycle count workflow data / normalized cycle count items
- preserve top-level task summary fields such as `product_name`, `product_barcode`, and `product_image`

## Rules

- `products` wins over legacy `expectedLines`
- zero-quantity products are excluded entirely
- stable key priority: `barcode`, then `product_id`, then `name`
- image priority for each line: `image`, then `product_image` if needed
- if `products` is absent, fall back to old cycle count parsing

## UI Impact

No new UI concept is needed. The existing two-page cycle count screen already works if `TaskEntity.cycleCountItems` exposes the parsed `products` entries.

## Testing

Add repository parsing coverage for:

- `cycle_count` payload with `products`
- zero-quantity products hidden
- non-zero products retained with barcode/name/image/quantity
- fallback to previous cycle count shape
