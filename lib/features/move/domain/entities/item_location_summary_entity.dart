import 'item_location_entity.dart';

class ItemLocationSummaryEntity {
  const ItemLocationSummaryEntity({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    this.itemImageUrl,
    required this.totalQuantity,
    required this.locations,
  });

  final int itemId;
  final String itemName;
  final String barcode;
  final String? itemImageUrl;
  final int totalQuantity;
  final List<ItemLocationEntity> locations;

  List<ItemLocationEntity> get shelfLocations =>
      locations.where((l) => l.isShelf).toList()
        ..sort((a, b) => a.zone.compareTo(b.zone));

  List<ItemLocationEntity> get bulkLocations =>
      locations.where((l) => l.isBulk).toList()
        ..sort((a, b) => a.zone.compareTo(b.zone));
}
