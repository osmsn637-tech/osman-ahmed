import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/features/move/data/models/item_location_summary_model.dart';

void main() {
  group('ItemLocationSummaryModel', () {
    test('parses mobile lookup payload keys (product_*)', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '24314',
        'product_name': 'Hajar Water 330ml',
        'product_image': '',
        'barcode': '6287009170024',
        'total_quantity': 0,
        'locations': const [],
      });

      expect(model.itemId, 24314);
      expect(model.itemName, 'Hajar Water 330ml');
      expect(model.itemImageUrl, isNull);
      expect(model.barcode, '6287009170024');
      expect(model.totalQuantity, 0);
    });

    test('parses location fields when ids and quantities are numeric strings', () {
      final model = ItemLocationSummaryModel.fromJson({
        'item_id': 10,
        'item_name': 'Sample',
        'barcode': '1234',
        'total_quantity': '17',
        'locations': [
          {
            'location_id': '101',
            'zone': 'A',
            'type': 'shelf',
            'code': 'A-01',
            'quantity': '12',
          },
        ],
      });

      expect(model.totalQuantity, 17);
      expect(model.locations, hasLength(1));
      expect(model.locations.first.locationId, 101);
      expect(model.locations.first.quantity, 12);
    });

    test('parses lookup payload with uuid locations and infers shelf/bulk from location_code', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '730',
        'product_name': 'Pepsi Zero 990ml',
        'product_image': 'http://img.qeu.app/products/012000065248/012000065248_20260103135844.jpg',
        'barcode': '012000065248',
        'total_quantity': 358,
        'locations': [
          {
            'location_id': '019b4267-e903-71be-9568-1f5af17b9955',
            'location_code': 'Z05-E03-SS-L02-P01',
            'quantity': 70,
            'available_quantity': 70,
          },
          {
            'location_id': '019b4267-f5f1-72e3-8a45-15d7e3f24e83',
            'location_code': 'Z05-E05-BLK-L01-P01',
            'quantity': 288,
            'available_quantity': 288,
          },
        ],
      });

      expect(model.itemId, 730);
      expect(model.itemName, 'Pepsi Zero 990ml');
      expect(model.barcode, '012000065248');
      expect(model.totalQuantity, 358);
      expect(model.locations, hasLength(2));
      expect(model.locations.first.type, 'shelf');
      expect(model.locations.first.zone, 'Z05');
      expect(model.locations.first.quantity, 70);
      expect(model.locations.last.type, 'bulk');
      expect(model.locations.last.zone, 'Z05');
      expect(model.locations.last.quantity, 288);
      expect(model.locations.first.locationId, isNot(0));
      expect(model.locations.last.locationId, isNot(0));
    });

    test('parses nested product map and normalizes image url to https', () {
      final model = ItemLocationSummaryModel.fromJson({
        'data': {
          'unused': true,
        },
        'product': {
          'product_id': '730',
          'product_name': 'بيبسي زيرو مشروب غازي 990 مل',
          'product_image':
              'http://img.qeu.app/products/012000065248/012000065248_20260103135844.jpg',
        },
        'barcode': '012000065248',
        'total_quantity': 358,
        'locations': const [],
      });

      expect(model.itemId, 730);
      expect(model.itemName, 'بيبسي زيرو مشروب غازي 990 مل');
      expect(
        model.itemImageUrl,
        'https://img.qeu.app/products/012000065248/012000065248_20260103135844.jpg',
      );
    });
  });
}
