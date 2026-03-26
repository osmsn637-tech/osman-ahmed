import '../../../../shared/utils/location_codes.dart';

enum LocationType { shelf, bulk, unknown }

extension LocationTypeLabel on LocationType {
  String get label {
    switch (this) {
      case LocationType.shelf:
        return 'Shelf';
      case LocationType.bulk:
        return 'Bulk';
      case LocationType.unknown:
        return 'Unknown';
    }
  }
}

LocationType detectLocationType(String? location) {
  if (location == null || location.trim().isEmpty) return LocationType.unknown;

  final normalized = location.trim().toUpperCase();
  if (isCompactShelfLocation(normalized)) {
    return LocationType.shelf;
  }
  if (isBulkLocationCode(normalized)) {
    return LocationType.bulk;
  }

  final parts = normalized.split('-');
  if (parts.length == 4 &&
      parts[0].startsWith('Z') &&
      parts[1].startsWith('C') &&
      parts[2].startsWith('L') &&
      parts[3].startsWith('P')) {
    return LocationType.shelf;
  }

  if (parts.length == 5 &&
      parts[0].startsWith('Z') &&
      parts[1] == 'BLK' &&
      parts[2].startsWith('C') &&
      parts[3].startsWith('L') &&
      parts[4].startsWith('P')) {
    return LocationType.bulk;
  }

  return LocationType.unknown;
}
