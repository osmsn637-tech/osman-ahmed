import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/shared/utils/location_codes.dart';

void main() {
  group('ground location aliases', () {
    test('recognizes A-GRND and B-GRND as ground location codes', () {
      expect(isGroundLocationCode('Z03-PT01-A-GRND-L01-P01'), isTrue);
      expect(isGroundLocationCode('Z03-PT01-B-GRND-L01-P01'), isTrue);
    });

    test('treats A-GRND and B-GRND as recognized location codes', () {
      expect(isRecognizedLocationCode('Z03-PT01-A-GRND-L01-P01'), isTrue);
      expect(isRecognizedLocationCode('Z03-PT01-B-GRND-L01-P01'), isTrue);
    });
  });
}
