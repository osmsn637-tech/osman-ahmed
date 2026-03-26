class VersionComparator {
  const VersionComparator();

  bool isBelowMinimum(String installedVersion, String minimumVersion) {
    final comparison = compare(installedVersion, minimumVersion);
    return comparison != null && comparison < 0;
  }

  int? compare(String left, String right) {
    final leftParts = _parse(left);
    final rightParts = _parse(right);
    if (leftParts == null || rightParts == null) {
      return null;
    }

    for (var index = 0; index < 3; index++) {
      final diff = leftParts[index].compareTo(rightParts[index]);
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }

  List<int>? _parse(String input) {
    final normalized = input.split('+').first.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final rawParts = normalized.split('.');
    if (rawParts.length > 3) {
      return null;
    }

    final parsed = <int>[];
    for (final part in rawParts) {
      final value = int.tryParse(part);
      if (value == null) {
        return null;
      }
      parsed.add(value);
    }

    while (parsed.length < 3) {
      parsed.add(0);
    }
    return parsed;
  }
}
