import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/move/data/datasources/item_remote_data_source.dart';
import 'package:wherehouse/features/move/domain/entities/stock_adjustment_params.dart';

void main() {
  test('adjustStock uses correct-product endpoint with one correction', () async {
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
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio(), const ErrorMapper());

  String lastPostPath = '';
  dynamic lastPostData;

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
    final payload = <String, dynamic>{'ok': true};
    final parsed = parser != null ? parser(payload) : payload as T;
    return Success<T>(parsed);
  }
}
