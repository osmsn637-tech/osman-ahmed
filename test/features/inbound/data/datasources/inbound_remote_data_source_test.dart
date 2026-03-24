import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/errors/error_mapper.dart';
import 'package:wherehouse/core/network/api_client.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/inbound/data/datasources/inbound_remote_data_source.dart';
import 'package:wherehouse/features/inbound/domain/entities/inbound_entities.dart';

void main() {
  test(
      'scanReceipt sends po_number and prefers expected quantity from the response',
      () async {
    final client = _FakeApiClient(
      getPayload: <String, dynamic>{
        'receiptId': 'receipt-1001',
        'po_number': 'PO-1001',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'item-1',
            'product_name': 'Blue Mug',
            'barcode': 'SKU-001',
            'receiptQuantity': 4,
            'expected_quantity': 9,
            'image_url': 'https://example.com/blue-mug.png',
          },
        ],
      },
    );
    final dataSource = InboundRemoteDataSource(client);

    final result = await dataSource.scanReceipt('PO-1001');

    expect(client.lastGetPath, '/mobile/v1/inbound/receipts/scan-by-po');
    expect(client.lastGetQueryParameters, <String, dynamic>{
      'po_number': 'PO-1001',
    });
    expect(result, isA<Success<InboundReceiptScanResult>>());

    final scanResult = (result as Success<InboundReceiptScanResult>).data;
    expect(scanResult.poNumber, 'PO-1001');
    expect(scanResult.items, hasLength(1));
    expect(scanResult.items.single.itemName, 'Blue Mug');
    expect(scanResult.items.single.expectedQuantity, 9);
    expect(
      scanResult.items.single.imageUrl,
      'https://example.com/blue-mug.png',
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.getPayload}) : super(Dio(), const ErrorMapper());

  final dynamic getPayload;
  String lastGetPath = '';
  Map<String, dynamic> lastGetQueryParameters = <String, dynamic>{};

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    lastGetPath = path;
    lastGetQueryParameters = queryParameters ?? <String, dynamic>{};
    final parsed = parser != null ? parser(getPayload) : getPayload as T;
    return Success<T>(parsed);
  }
}
