import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/move/data/models/item_location_summary_model.dart';

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

    test('parses location fields when ids and quantities are numeric strings',
        () {
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
      expect(model.locations.first.locationId, '101');
      expect(model.locations.first.quantity, 12);
    });

    test(
        'parses lookup payload with uuid locations and infers shelf/bulk from location_code',
        () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '730',
        'product_name': 'Pepsi Zero 990ml',
        'product_image':
            'http://img.qeu.app/products/012000065248/012000065248_20260103135844.jpg',
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

    test('infers shelf and ground from SB and GRND location codes', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '16716',
        'product_name': 'Tortilla Rolls',
        'barcode': '6281100362760',
        'total_quantity': 100,
        'locations': [
          {
            'location_id': '019b4267-dcf4-72db-8823-deeb22003ec4',
            'location_code': 'Z03-C16-SB-L01-P03',
            'quantity': 0,
            'available_quantity': 0,
          },
          {
            'location_id': '019bd2eb-9536-703c-b20b-e58cedecc1f3',
            'location_code': 'Z03-PT01-GRND-L01-P01',
            'quantity': 100,
            'available_quantity': 100,
          },
        ],
      });

      expect(model.locations, hasLength(2));
      expect(model.locations.first.type, 'shelf');
      expect(model.locations.last.type, 'ground');
      expect(
        model.toEntity().groundLocations.map((location) => location.code),
        ['Z03-PT01-GRND-L01-P01'],
      );
    });

    test('infers ground from A-GRND and B-GRND location codes', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '16716',
        'product_name': 'Tortilla Rolls',
        'barcode': '6281100362760',
        'total_quantity': 200,
        'locations': [
          {
            'location_id': 'ground-a',
            'location_code': 'Z03-PT01-A-GRND-L01-P01',
            'quantity': 75,
            'available_quantity': 75,
          },
          {
            'location_id': 'ground-b',
            'location_code': 'Z03-PT01-B-GRND-L01-P01',
            'quantity': 125,
            'available_quantity': 125,
          },
        ],
      });

      expect(
        model.locations.every((location) => location.type == 'ground'),
        isTrue,
      );
      expect(
        model.toEntity().groundLocations.map((location) => location.code),
        [
          'Z03-PT01-A-GRND-L01-P01',
          'Z03-PT01-B-GRND-L01-P01',
        ],
      );
    });

    test('infers ground from plain A-GRND backend location codes', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '17303',
        'product_name': 'كيت كات اصبعين 20.5جم',
        'product_image':
            'http://img.qeu.app/products/6294017130551/6294017130551_image.webp',
        'sku': 'ERP-43346',
        'barcode': '6294017130551',
        'total_quantity': 230060,
        'total_reserved': 32,
        'total_available': 230008,
        'total_picked': 20,
        'locations': [
          {
            'warehouse_id': '019966c3-0f2c-7950-ae4d-ae6b1d9a1fa7',
            'warehouse_name': 'النخيل',
            'location_id': '3e5ace4e-fc66-4764-b5e0-e83d99672435',
            'location_code': 'A-GRND',
            'quantity': 230060,
            'reserved_quantity': 32,
            'available_quantity': 230008,
            'batch_number': '',
            'expiry_date': '1970-01-01',
            'picked_quantity': 20,
          },
        ],
      });

      expect(model.locations, hasLength(1));
      expect(model.locations.single.type, 'ground');
      expect(model.locations.single.zone, 'A');
      expect(
          model.toEntity().groundLocations.map((location) => location.code), [
        'A-GRND',
      ]);
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

    test('parses compact shelf location codes from locations array payload',
        () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '11250',
        'product_name': 'فقيه دجاج 900 جرام',
        'product_image': 'http://img.qeu.app/products/6281101930050/1.png',
        'sku': '',
        'barcode': '6281101930050',
        'total_quantity': 1,
        'locations': [
          {
            'warehouse_id': '019966c3-0f2c-7950-ae4d-ae6b1d9a1fa7',
            'warehouse_name': 'النخيل',
            'location_id': 'da643939-ef45-4846-9a92-06f04f034192',
            'location_code': 'A10.2',
            'quantity': 1,
            'reserved_quantity': 0,
            'available_quantity': 1,
            'batch_number': '',
            'expiry_date': '1970-01-01',
            'picked_quantity': 0,
          },
        ],
      });

      expect(model.itemId, 11250);
      expect(model.itemName, 'فقيه دجاج 900 جرام');
      expect(model.barcode, '6281101930050');
      expect(
        model.itemImageUrl,
        'https://img.qeu.app/products/6281101930050/1.png',
      );
      expect(model.locations, hasLength(1));
      expect(model.locations.single.code, 'A10.2');
      expect(model.locations.single.type, 'shelf');
      expect(model.toEntity().shelfLocations.single.code, 'A10.2');
    });

    test('parses B, C, and D compact shelf location codes as shelf', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '11250',
        'product_name': 'فقيه دجاج 900 جرام',
        'barcode': '6281101930050',
        'total_quantity': 3,
        'locations': [
          {
            'location_id': '1',
            'location_code': 'B10.2',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '2',
            'location_code': 'C08.1',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '3',
            'location_code': 'D01.7',
            'quantity': 1,
            'available_quantity': 1,
          },
        ],
      });

      expect(model.locations, hasLength(3));
      expect(model.locations.every((location) => location.type == 'shelf'),
          isTrue);
      expect(model.toEntity().shelfLocations.map((location) => location.code), [
        'B10.2',
        'C08.1',
        'D01.7',
      ]);
    });

    test('parses one-digit compact shelf codes as shelf', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '261',
        'product_name': 'برافو حفايض اطفال رقم7 ×36',
        'barcode': '6224000195113',
        'total_quantity': 4,
        'locations': [
          {
            'location_id': '1',
            'location_code': 'A2.2',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '2',
            'location_code': 'B2.2',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '3',
            'location_code': 'C3.1',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '4',
            'location_code': 'D4.7',
            'quantity': 1,
            'available_quantity': 1,
          },
        ],
      });

      expect(model.locations, hasLength(4));
      expect(model.locations.every((location) => location.type == 'shelf'),
          isTrue);
      expect(model.toEntity().shelfLocations.map((location) => location.code), [
        'A2.2',
        'B2.2',
        'C3.1',
        'D4.7',
      ]);
    });

    test('parses new bulk location formats as bulk', () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '261',
        'product_name': 'برافو حفايض اطفال رقم7 ×36',
        'barcode': '6224000195113',
        'total_quantity': 2,
        'locations': [
          {
            'location_id': '1',
            'location_code': 'BULK A2.2',
            'quantity': 1,
            'available_quantity': 1,
          },
          {
            'location_id': '2',
            'location_code': 'BULK-C3.1',
            'quantity': 1,
            'available_quantity': 1,
          },
        ],
      });

      expect(model.locations, hasLength(2));
      expect(
          model.locations.every((location) => location.type == 'bulk'), isTrue);
      expect(model.toEntity().bulkLocations.map((location) => location.code), [
        'BULK A2.2',
        'BULK-C3.1',
      ]);
    });

    test(
        'falls back to location_code inference when api location_type is not canonical',
        () {
      final model = ItemLocationSummaryModel.fromJson({
        'product_id': '730',
        'product_name': 'Pepsi Zero 990ml',
        'barcode': '012000065248',
        'total_quantity': 358,
        'locations': [
          {
            'location_id': '1',
            'location_code': 'Z05-E03-SS-L02-P01',
            'location_type': 'pick_face',
            'quantity': 70,
          },
          {
            'location_id': '2',
            'location_code': 'Z05-E05-BLK-L01-P01',
            'location_type': 'reserve',
            'quantity': 288,
          },
        ],
      });

      expect(model.locations.first.type, 'shelf');
      expect(model.locations.last.type, 'bulk');
      expect(
        model.toEntity().shelfLocations.map((location) => location.code),
        ['Z05-E03-SS-L02-P01'],
      );
      expect(
        model.toEntity().bulkLocations.map((location) => location.code),
        ['Z05-E05-BLK-L01-P01'],
      );
    });
  });
}
