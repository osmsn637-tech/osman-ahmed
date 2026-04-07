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

  final String locationId;
  final String zone;
  final String type;
  final String code;
  final int quantity;

  factory ItemLocationModel.fromJson(Map<String, dynamic> json) {
    final rawLocationId =
        json['location_id'] ?? json['locationId'] ?? json['id'];
    final code = _readString(
      json['code'] ?? json['location_code'] ?? json['locationCode'],
    );
    final locationId = _readLocationId(rawLocationId, fallback: code);
    final parsedZone = _readString(
      json['zone'] ?? json['zone_name'] ?? json['zoneName'],
    );
    final parsedType = _readString(
      json['type'] ?? json['location_type'] ?? json['locationType'],
    );
    final zone = parsedZone.isNotEmpty ? parsedZone : _inferZoneFromCode(code);
    final type = _resolveType(parsedType, code);
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

  static String _readLocationId(dynamic value, {required String fallback}) {
    final parsed = _readString(value);
    return parsed.isNotEmpty ? parsed : fallback;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _resolveType(String rawType, String code) {
    final normalizedType = _normalizeKnownType(rawType);
    if (normalizedType.isNotEmpty) return normalizedType;

    final inferredType = _inferTypeFromCode(code);
    if (inferredType.isNotEmpty) return inferredType;

    return rawType.trim().toLowerCase();
  }

  static String _normalizeKnownType(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'shelf':
      case 'ss':
      case 'sb':
      case 'display':
      case 'pick':
      case 'pick_face':
      case 'pick-face':
      case 'pickface':
        return 'shelf';
      case 'bulk':
      case 'blk':
      case 'reserve':
      case 'storage':
      case 'backstock':
        return 'bulk';
      case 'ground':
      case 'grnd':
      case 'floor':
        return 'ground';
      default:
        break;
    }

    if (normalized.contains('shelf')) return 'shelf';
    if (normalized.contains('bulk')) return 'bulk';
    if (normalized.contains('ground')) return 'ground';
    return '';
  }

  static String _inferTypeFromCode(String code) {
    final upper = code.toUpperCase();
    if (isCompactShelfLocation(upper)) return 'shelf';
    if (isGroundLocationCode(upper)) return 'ground';
    if (isBulkLocationCode(upper)) return 'bulk';
    if (upper.contains('-SS-')) return 'shelf';
    if (upper.contains('-SB-')) return 'shelf';
    if (upper.contains('-BLK-')) return 'bulk';
    if (upper.contains('-GRND-')) return 'ground';
    return '';
  }

  static String _inferZoneFromCode(String code) {
    if (code.isEmpty) return '';
    final normalizedZone = normalizeZoneCode(code);
    if (normalizedZone != null) return normalizedZone;
    final parts = code.split('-');
    return parts.isEmpty ? '' : parts.first.trim();
  }
}
