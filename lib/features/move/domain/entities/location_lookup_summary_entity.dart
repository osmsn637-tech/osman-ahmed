class LocationLookupSummaryEntity {
  const LocationLookupSummaryEntity({
    required this.locationId,
    required this.locationCode,
    required this.items,
  });

  final String locationId;
  final String locationCode;
  final List<LocationLookupItemEntity> items;

  int get totalItems => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

class LocationLookupItemEntity {
  const LocationLookupItemEntity({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.quantity,
    this.pickedQuantity = 0,
    this.imageUrl,
  });

  final int itemId;
  final String itemName;
  final String barcode;
  final int quantity;
  final int pickedQuantity;
  final String? imageUrl;
}
