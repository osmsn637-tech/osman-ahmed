import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/app_update/domain/services/version_comparator.dart';

void main() {
  const comparator = VersionComparator();

  test('reports installed version below minimum as outdated', () {
    expect(comparator.isBelowMinimum('1.2.0', '1.2.1'), isTrue);
  });

  test('treats equal versions as supported', () {
    expect(comparator.isBelowMinimum('1.2.1', '1.2.1'), isFalse);
  });

  test('ignores build metadata while comparing versions', () {
    expect(comparator.isBelowMinimum('1.2.1+3', '1.2.1'), isFalse);
  });
}
