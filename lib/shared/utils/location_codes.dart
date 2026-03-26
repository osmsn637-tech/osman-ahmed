bool isCompactShelfLocation(String? value) {
  if (value == null) return false;
  return _compactShelfPattern.hasMatch(value.trim().toUpperCase());
}

bool isBulkLocationCode(String? value) {
  if (value == null) return false;
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return false;
  if (_compactBulkPattern.hasMatch(normalized)) return true;
  if (normalized.contains('-BLK-') || normalized.contains('-GRND-')) {
    return true;
  }
  return false;
}

bool isRecognizedLocationCode(String? value) {
  if (value == null) return false;
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return false;
  if (isCompactShelfLocation(normalized)) return true;
  if (isBulkLocationCode(normalized)) return true;
  if (normalized.contains('-SS-') || normalized.contains('-SB-')) {
    return true;
  }
  if (normalized.contains('-BLK-') || normalized.contains('-GRND-')) {
    return true;
  }
  return false;
}

String? normalizeZoneCode(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  final explicitZone = _explicitZonePattern.firstMatch(normalized);
  if (explicitZone != null) {
    return explicitZone.group(1);
  }

  final compactShelf = _compactShelfPattern.firstMatch(normalized);
  if (compactShelf != null) {
    return compactShelf.group(1);
  }

  final compactBulk = _compactBulkPattern.firstMatch(normalized);
  if (compactBulk != null) {
    return compactBulk.group(1)?.substring(0, 1);
  }

  final legacyZone = RegExp(r'\bZ(\d{1,3})\b').firstMatch(normalized);
  if (legacyZone != null) {
    return 'Z${legacyZone.group(1)!.padLeft(2, '0')}';
  }

  return null;
}

String formatZoneForDisplay(String? value) {
  final normalized = normalizeZoneCode(value);
  if (normalized != null && normalized.isNotEmpty) {
    return normalized;
  }
  final fallback = value?.trim() ?? '';
  if (fallback.isEmpty) return '--';
  return fallback;
}

final RegExp _explicitZonePattern = RegExp(r'^(?:ZONE[\s-]*)?([ABCD])$');
final RegExp _compactShelfPattern = RegExp(r'^([ABCD])\d{1,2}\.\d+$');
final RegExp _compactBulkPattern =
    RegExp(r'^BULK(?:[\s-]*)([ABCD]\d{1,2}\.\d+)$');
