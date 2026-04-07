import '../../domain/entities/item_location_summary_entity.dart';
import 'item_location_model.dart';

class ItemLocationSummaryModel {
  const ItemLocationSummaryModel({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.warehouseId,
    required this.itemImageUrl,
    required this.totalQuantity,
    required this.locations,
  });

  final int itemId;
  final String itemName;
  final String barcode;
  final String? warehouseId;
  final String? itemImageUrl;
  final int totalQuantity;
  final List<ItemLocationModel> locations;

  factory ItemLocationSummaryModel.fromJson(Map<String, dynamic> json) {
    final productMap = _readMap(json['product']) ?? _readMap(json['item']);

    final rawLocations = json['locations'];
    final locs = rawLocations is List
        ? rawLocations
            .whereType<Map>()
            .map(
                (e) => ItemLocationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ItemLocationModel>[];
    final firstLocationMap = rawLocations is List && rawLocations.isNotEmpty
        ? _readMap(rawLocations.first)
        : null;

    final itemId = _readInt(json['item_id'] ??
        json['itemId'] ??
        json['product_id'] ??
        json['id'] ??
        productMap?['product_id'] ??
        productMap?['id']);
    final itemName = _readString(json['item_name'] ??
        json['itemName'] ??
        json['product_name'] ??
        json['name'] ??
        productMap?['product_name'] ??
        productMap?['name']);
    final barcode = _readString(json['barcode'] ?? json['sku']);
    final warehouseId = _readNullableString(
      json['warehouse_id'] ??
          json['warehouseId'] ??
          productMap?['warehouse_id'] ??
          productMap?['warehouseId'] ??
          firstLocationMap?['warehouse_id'] ??
          firstLocationMap?['warehouseId'],
    );
    final itemImageUrl = _normalizeImageUrl(_readNullableString(
      json['item_image_url'] ??
          json['itemImageUrl'] ??
          json['product_image'] ??
          json['image_url'] ??
          productMap?['product_image'] ??
          productMap?['image_url'],
    ));
    final totalQuantity = _readInt(
      json['total_quantity'] ??
          json['totalQuantity'] ??
          json['total_available'] ??
          json['totalAvailable'],
    );

    return ItemLocationSummaryModel(
      itemId: itemId,
      itemName: itemName,
      barcode: barcode,
      warehouseId: warehouseId,
      itemImageUrl: itemImageUrl,
      totalQuantity: totalQuantity,
      locations: locs,
    );
  }

  ItemLocationSummaryEntity toEntity() => ItemLocationSummaryEntity(
        itemId: itemId,
        itemName: itemName,
        barcode: barcode,
        warehouseId: warehouseId,
        itemImageUrl: itemImageUrl,
        totalQuantity: totalQuantity,
        locations: locations.map((e) => e.toEntity()).toList(),
      );

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    final parsed = _readString(value);
    return parsed.isEmpty ? null : parsed;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _normalizeImageUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://')) {
      return 'https://${value.substring('http://'.length)}';
    }
    return value;
  }
}
