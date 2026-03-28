import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/move/data/datasources/item_remote_data_source.dart';
import 'package:wherehouse/features/move/domain/entities/location_lookup_summary_entity.dart';
import 'package:wherehouse/features/move/domain/entities/stock_adjustment_params.dart';

void main() {
  test('adjustStock uses correct-product endpoint with one correction',
      () async {
    final client = _FakeApiClient();
    final dataSource = ItemRemoteDataSourceImpl(client);

    await dataSource.adjustStock(
      const StockAdjustmentParams(
        itemId: 1001,
        locationId: 2,
        locationBarcode: 'Z012-BLK-A01-L02-P05',
        newQuantity: 7,
        reason: 'Count Correction',
        workerId: 'worker-1',
      ),
    );

    expect(
      client.lastPostPath,
      '/mobile/v1/adjustments/correct-product',
    );
    expect(
      client.lastPostData,
      <String, dynamic>{
        'product_id': 1001,
        'corrections': [
          {
            'location_barcode': 'Z012-BLK-A01-L02-P05',
            'actual_quantity': 7,
          }
        ],
      },
    );
  });

  test('scanLocation posts to location-scan endpoint and parses items',
      () async {
    final client = _FakeApiClient()
      ..loginResponse = <String, dynamic>{
        'token': 'lookup-token',
      }
      ..locationScanResponse = <String, dynamic>{
        'data': <String, dynamic>{
          'location_id': 'loc-77',
          'location_code': 'A10.2',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'item_id': 1001,
              'item_name': 'Hajer Water',
              'barcode': '6287009170024',
              'quantity': 12,
              'picked_quantity': 3,
              'image_url': 'https://example.com/water.png',
            },
          ],
        },
      };
    final dataSource = ItemRemoteDataSourceImpl(client);

    final result = await dataSource.scanLocation('A10.2');

    expect(
      client.locationScanPostPath,
      '/mobile/v1/locations/scan',
    );
    expect(
      client.locationScanPostData,
      <String, dynamic>{
        'barcode': 'A10.2',
      },
    );
    expect(result, isA<Success<LocationLookupSummaryEntity>>());
    final summary = (result as Success<LocationLookupSummaryEntity>).data;
    expect(summary.locationId, 'loc-77');
    expect(summary.locationCode, 'A10.2');
    expect(summary.items, hasLength(1));
    expect(summary.items.first.itemName, 'Hajer Water');
    expect(summary.items.first.barcode, '6287009170024');
    expect(summary.items.first.quantity, 12);
    expect(summary.items.first.pickedQuantity, 3);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio(), const ErrorMapper());

  String lastPostPath = '';
  dynamic lastPostData;
  String locationScanPostPath = '';
  dynamic locationScanPostData;
  dynamic loginResponse = <String, dynamic>{'token': 'lookup-token'};
  dynamic defaultPostResponse = <String, dynamic>{'ok': true};
  dynamic locationScanResponse = <String, dynamic>{'ok': true};

  @override
  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    final payload = switch (path) {
      'https://api.qeu.info/v1/inventory/login' => loginResponse,
      '/mobile/v1/locations/scan' => () {
          locationScanPostPath = path;
          locationScanPostData = data;
          return locationScanResponse;
        }(),
      _ => defaultPostResponse,
    };
    final parsed = parser != null ? parser(payload) : payload as T;
    return Success<T>(parsed);
  }
}
