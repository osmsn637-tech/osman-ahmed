import '../../domain/entities/location_lookup_summary_entity.dart';

class LocationLookupSummaryModel {
  const LocationLookupSummaryModel({
    required this.locationId,
    required this.locationCode,
    required this.items,
  });

  final String locationId;
  final String locationCode;
  final List<LocationLookupItemModel> items;

  factory LocationLookupSummaryModel.fromJson(
    Map<String, dynamic> json, {
    required String scannedCode,
  }) {
    final payload = _unwrapPayload(json);
    final locationMap = _readMap(payload['location']);
    final rawItems = payload['items'] ?? payload['products'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (entry) => LocationLookupItemModel.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(growable: false)
        : const <LocationLookupItemModel>[];

    final locationCode = _readString(
      payload['location_code'] ??
          payload['locationCode'] ??
          payload['code'] ??
          payload['barcode'] ??
          locationMap?['location_code'] ??
          locationMap?['locationCode'] ??
          locationMap?['code'] ??
          locationMap?['barcode'],
    );

    return LocationLookupSummaryModel(
      locationId: _readString(
        payload['location_id'] ??
            payload['locationId'] ??
            payload['id'] ??
            locationMap?['location_id'] ??
            locationMap?['locationId'] ??
            locationMap?['id'],
      ),
      locationCode: locationCode.isEmpty ? scannedCode : locationCode,
      items: items,
    );
  }

  LocationLookupSummaryEntity toEntity() => LocationLookupSummaryEntity(
        locationId: locationId,
        locationCode: locationCode,
        items: items.map((item) => item.toEntity()).toList(growable: false),
      );

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    final nested = _readMap(json['data']);
    return nested ?? json;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

class LocationLookupItemModel {
  const LocationLookupItemModel({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.quantity,
    this.imageUrl,
  });

  final int itemId;
  final String itemName;
  final String barcode;
  final int quantity;
  final String? imageUrl;

  factory LocationLookupItemModel.fromJson(Map<String, dynamic> json) {
    final productMap = _readMap(json['product']) ?? _readMap(json['item']);

    return LocationLookupItemModel(
      itemId: _readInt(
        json['item_id'] ??
            json['itemId'] ??
            json['product_id'] ??
            json['productId'] ??
            json['id'] ??
            productMap?['item_id'] ??
            productMap?['itemId'] ??
            productMap?['product_id'] ??
            productMap?['productId'] ??
            productMap?['id'],
      ),
      itemName: _readString(
        json['item_name'] ??
            json['itemName'] ??
            json['product_name'] ??
            json['productName'] ??
            json['name'] ??
            productMap?['item_name'] ??
            productMap?['itemName'] ??
            productMap?['product_name'] ??
            productMap?['productName'] ??
            productMap?['name'],
      ),
      barcode: _readString(
        json['barcode'] ??
            json['item_barcode'] ??
            json['itemBarcode'] ??
            json['product_barcode'] ??
            json['productBarcode'] ??
            json['sku'] ??
            productMap?['barcode'] ??
            productMap?['item_barcode'] ??
            productMap?['itemBarcode'] ??
            productMap?['product_barcode'] ??
            productMap?['productBarcode'] ??
            productMap?['sku'],
      ),
      quantity: _readInt(
        json['quantity'] ??
            json['available_quantity'] ??
            json['availableQuantity'] ??
            json['stock_quantity'] ??
            json['stockQuantity'] ??
            json['system_quantity'] ??
            json['systemQuantity'] ??
            json['actual_quantity'] ??
            json['actualQuantity'],
      ),
      imageUrl: _normalizeImageUrl(
        _readNullableString(
          json['image_url'] ??
              json['imageUrl'] ??
              json['item_image_url'] ??
              json['itemImageUrl'] ??
              json['product_image'] ??
              json['productImage'] ??
              productMap?['image_url'] ??
              productMap?['imageUrl'] ??
              productMap?['item_image_url'] ??
              productMap?['itemImageUrl'] ??
              productMap?['product_image'] ??
              productMap?['productImage'],
        ),
      ),
    );
  }

  LocationLookupItemEntity toEntity() => LocationLookupItemEntity(
        itemId: itemId,
        itemName: itemName,
        barcode: barcode,
        quantity: quantity,
        imageUrl: imageUrl,
      );

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

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

  static String? _normalizeImageUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://')) {
      return 'https://${value.substring('http://'.length)}';
    }
    return value;
  }
}
