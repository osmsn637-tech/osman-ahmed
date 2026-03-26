import '../../domain/entities/item_location_entity.dart';
import '../../../../shared/utils/location_codes.dart';

class ItemLocationModel {
  const ItemLocationModel({
    required this.locationId,
    required this.zone,
    required this.type,
    required this.code,
    required this.quantity,
  });

  final int locationId;
  final String zone;
  final String type;
  final String code;
  final int quantity;

  factory ItemLocationModel.fromJson(Map<String, dynamic> json) {
    final rawLocationId = json['location_id'] ?? json['locationId'] ?? json['id'];
    final code = _readString(
      json['code'] ?? json['location_code'] ?? json['locationCode'],
    );
    final parsedLocationId = _readInt(rawLocationId);
    final locationId = parsedLocationId != 0
        ? parsedLocationId
        : _stableIntFromString(_readString(rawLocationId).isNotEmpty
            ? _readString(rawLocationId)
            : code);
    final parsedZone = _readString(
      json['zone'] ?? json['zone_name'] ?? json['zoneName'],
    );
    final parsedType = _readString(
      json['type'] ?? json['location_type'] ?? json['locationType'],
    );
    final zone = parsedZone.isNotEmpty ? parsedZone : _inferZoneFromCode(code);
    final type = parsedType.isNotEmpty ? parsedType : _inferTypeFromCode(code);
    final quantity = _readInt(
      json['quantity'] ??
          json['available_quantity'] ??
          json['availableQuantity'] ??
          json['stock_quantity'] ??
          json['stockQuantity'],
    );

    return ItemLocationModel(
      locationId: locationId,
      zone: zone,
      type: type,
      code: code,
      quantity: quantity,
    );
  }

  ItemLocationEntity toEntity() => ItemLocationEntity(
        locationId: locationId,
        zone: zone,
        type: type,
        code: code,
        quantity: quantity,
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

  static String _inferTypeFromCode(String code) {
    final upper = code.toUpperCase();
    if (isCompactShelfLocation(upper)) return 'shelf';
    if (isBulkLocationCode(upper)) return 'bulk';
    if (upper.contains('-SS-')) return 'shelf';
    if (upper.contains('-SB-')) return 'shelf';
    if (upper.contains('-BLK-')) return 'bulk';
    if (upper.contains('-GRND-')) return 'bulk';
    return '';
  }

  static String _inferZoneFromCode(String code) {
    if (code.isEmpty) return '';
    final normalizedZone = normalizeZoneCode(code);
    if (normalizedZone != null) return normalizedZone;
    final parts = code.split('-');
    return parts.isEmpty ? '' : parts.first.trim();
  }

  static int _stableIntFromString(String value) {
    if (value.isEmpty) return 0;
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }
}
