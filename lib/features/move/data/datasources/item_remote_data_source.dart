import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/item_detail.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/location_lookup_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';
import '../models/item_location_summary_model.dart';
import '../models/location_lookup_summary_model.dart';
import '../models/location_stock_model.dart';
import '../models/item_detail_model.dart';

abstract class ItemRemoteDataSource {
  Future<Result<ItemDetail>> fetchStock(String barcode);
  Future<Result<ItemLocationSummaryEntity>> fetchItemLocations(String barcode);
  Future<Result<LocationLookupSummaryEntity>> scanLocation(String barcode);
  Future<Result<void>> adjustStock(StockAdjustmentParams params);
}

class ItemRemoteDataSourceImpl implements ItemRemoteDataSource {
  ItemRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Result<ItemDetail>> fetchStock(String barcode) {
    return _client.get<ItemDetail>(AppEndpoints.itemStock(barcode),
        parser: (data) {
      if (data is Map<String, dynamic>) {
        return ItemDetailModel.fromJson(data);
      }
      if (data is List) {
        // fallback: list of stocks without metadata
        final stocks = data
            .map((e) => LocationStockModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ItemDetailModel(barcode: barcode, name: '', stocks: stocks);
      }
      return ItemDetailModel(barcode: barcode, name: '', stocks: const []);
    });
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> fetchItemLocations(
      String barcode) async {
    final normalized = _normalizeBarcode(barcode);
    if (normalized.isEmpty) {
      return const Failure<ItemLocationSummaryEntity>(
        ValidationException('Enter a valid barcode'),
      );
    }
    return _callLookupEndpoint(normalized);
  }

  @override
  Future<Result<LocationLookupSummaryEntity>> scanLocation(
      String barcode) async {
    final normalized = _normalizeBarcode(barcode);
    if (normalized.isEmpty) {
      return const Failure<LocationLookupSummaryEntity>(
        ValidationException('Enter a valid location barcode'),
      );
    }
    return _callLocationLookupEndpoint(normalized);
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) {
    return _client.post<void>(
      AppEndpoints.correctProductAdjustment,
      data: {
        'product_id': params.itemId,
        'corrections': [
          {
            'location_barcode': params.locationBarcode,
            'actual_quantity': params.newQuantity,
          }
        ],
        if (params.note != null && params.note!.trim().isNotEmpty)
          'notes': params.note!.trim(),
      },
    );
  }

  Map<String, dynamic> _extractLookupPayload(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    return data;
  }

  Future<Result<ItemLocationSummaryEntity>> _callLookupEndpoint(String barcode) {
    return _client.get<ItemLocationSummaryEntity>(
      AppEndpoints.lookupProductByBarcode(barcode),
      parser: (data) {
        final payload = _extractLookupPayload(data);
        return ItemLocationSummaryModel.fromJson(payload).toEntity();
      },
    );
  }

  Future<Result<LocationLookupSummaryEntity>> _callLocationLookupEndpoint(
    String barcode,
  ) {
    return _client.post<LocationLookupSummaryEntity>(
      AppEndpoints.locationScan,
      data: <String, dynamic>{
        'barcode': barcode,
      },
      parser: (data) {
        final payload = _extractLookupPayload(data);
        return LocationLookupSummaryModel.fromJson(
          payload,
          scannedCode: barcode,
        ).toEntity();
      },
    );
  }

  String _normalizeBarcode(String barcode) {
    return barcode.replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '').trim();
  }
}
