import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/dashboard/presentation/shared/location_format.dart';

void main() {
  test('detectLocationType recognizes compact backend shelf codes', () {
    expect(detectLocationType('A03.4'), LocationType.shelf);
    expect(detectLocationType('a12.9'), LocationType.shelf);
    expect(detectLocationType('A2.2'), LocationType.shelf);
    expect(detectLocationType('B10.2'), LocationType.shelf);
    expect(detectLocationType('B2.2'), LocationType.shelf);
    expect(detectLocationType('C08.1'), LocationType.shelf);
    expect(detectLocationType('C3.1'), LocationType.shelf);
    expect(detectLocationType('D01.7'), LocationType.shelf);
    expect(detectLocationType('D4.7'), LocationType.shelf);
  });

  test('detectLocationType recognizes new bulk location formats', () {
    expect(detectLocationType('BULK A2.2'), LocationType.bulk);
    expect(detectLocationType('bulkB10.2'), LocationType.bulk);
    expect(detectLocationType('BULK-C3.1'), LocationType.bulk);
    expect(detectLocationType('bulk d4.7'), LocationType.bulk);
    expect(detectLocationType('BULK-A117'), LocationType.bulk);
  });

  test('detectLocationType keeps legacy shelf and bulk parsing intact', () {
    expect(detectLocationType('Z01-C01-L01-P01'), LocationType.shelf);
    expect(detectLocationType('Z01-BLK-C01-L01-P01'), LocationType.bulk);
  });
}
