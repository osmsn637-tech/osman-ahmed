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
  static const String _lookupAuthEmail = 'a.ali@qeu.app';
  static const String _lookupAuthPassword = 'Qeu@2025';
  static String? _sharedLookupBearerToken;

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
    return _fetchItemLocationsWithAuth(normalized);
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
    return _scanLocationWithAuth(normalized);
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

  Future<Result<ItemLocationSummaryEntity>> _fetchItemLocationsWithAuth(
    String barcode,
  ) async {
    final tokenResult = await _ensureLookupBearerToken();
    if (tokenResult is Failure<String>) {
      return Failure<ItemLocationSummaryEntity>(tokenResult.error);
    }

    final token = (tokenResult as Success<String>).data;
    final lookupResult = await _callLookupEndpoint(barcode, token: token);
    if (lookupResult is Success<ItemLocationSummaryEntity>) {
      return lookupResult;
    }

    final lookupError =
        (lookupResult as Failure<ItemLocationSummaryEntity>).error;
    if (lookupError is AuthExpiredException ||
        lookupError is UnauthorizedException) {
      _sharedLookupBearerToken = null;
      final refreshedTokenResult = await _ensureLookupBearerToken();
      if (refreshedTokenResult is Failure<String>) {
        return Failure<ItemLocationSummaryEntity>(refreshedTokenResult.error);
      }

      final refreshedToken = (refreshedTokenResult as Success<String>).data;
      return _callLookupEndpoint(barcode, token: refreshedToken);
    }

    return Failure<ItemLocationSummaryEntity>(lookupError);
  }

  Future<Result<LocationLookupSummaryEntity>> _scanLocationWithAuth(
    String barcode,
  ) async {
    final tokenResult = await _ensureLookupBearerToken();
    if (tokenResult is Failure<String>) {
      return Failure<LocationLookupSummaryEntity>(tokenResult.error);
    }

    final token = (tokenResult as Success<String>).data;
    final lookupResult =
        await _callLocationLookupEndpoint(barcode, token: token);
    if (lookupResult is Success<LocationLookupSummaryEntity>) {
      return lookupResult;
    }

    final lookupError =
        (lookupResult as Failure<LocationLookupSummaryEntity>).error;
    if (lookupError is AuthExpiredException ||
        lookupError is UnauthorizedException) {
      _sharedLookupBearerToken = null;
      final refreshedTokenResult = await _ensureLookupBearerToken();
      if (refreshedTokenResult is Failure<String>) {
        return Failure<LocationLookupSummaryEntity>(refreshedTokenResult.error);
      }

      final refreshedToken = (refreshedTokenResult as Success<String>).data;
      return _callLocationLookupEndpoint(barcode, token: refreshedToken);
    }

    return Failure<LocationLookupSummaryEntity>(lookupError);
  }

  Future<Result<ItemLocationSummaryEntity>> _callLookupEndpoint(String barcode,
      {String token = ''}) {
    final authHeader = token.isNotEmpty
        ? <String, dynamic>{'Authorization': 'Bearer $token'}
        : null;

    return _client.get<ItemLocationSummaryEntity>(
      AppEndpoints.lookupProductByBarcode(barcode),
      headers: authHeader,
      parser: (data) {
        final payload = _extractLookupPayload(data);
        return ItemLocationSummaryModel.fromJson(payload).toEntity();
      },
    );
  }

  Future<Result<LocationLookupSummaryEntity>> _callLocationLookupEndpoint(
    String barcode, {
    String token = '',
  }) {
    final authHeader = token.isNotEmpty
        ? <String, dynamic>{'Authorization': 'Bearer $token'}
        : null;

    return _client.post<LocationLookupSummaryEntity>(
      AppEndpoints.locationScan,
      headers: authHeader,
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

  Future<Result<String>> _ensureLookupBearerToken() async {
    final cached = _sharedLookupBearerToken;
    if (cached != null && cached.isNotEmpty) {
      return Success<String>(cached);
    }

    final loginResult = await _client.post<Map<String, dynamic>>(
      AppEndpoints.qeuMobileLogin,
      data: const {
        'email': _lookupAuthEmail,
        'password': _lookupAuthPassword,
      },
      parser: (data) => _asMap(data),
    );

    return loginResult.when(
      success: (data) {
        final token = _extractBearerToken(data);
        if (token == null || token.isEmpty) {
          return const Failure<String>(
            ValidationException(
                'Could not extract bearer token from login response'),
          );
        }
        _sharedLookupBearerToken = token;
        return Success<String>(token);
      },
      failure: (error) => Failure<String>(error),
    );
  }

  String? _extractBearerToken(Map<String, dynamic> payload) {
    return _findTokenDeep(payload);
  }

  String? _pickTokenFromMap(Map<String, dynamic> map) {
    for (final key in const [
      'token',
      'access_token',
      'accessToken',
      'bearerToken',
      'bearer_token',
    ]) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final nestedTokens = map['tokens'];
    if (nestedTokens is Map<String, dynamic>) {
      for (final key in const [
        'token',
        'access_token',
        'accessToken',
      ]) {
        final value = nestedTokens[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String? _findTokenDeep(dynamic node) {
    if (node is Map<String, dynamic>) {
      final direct = _pickTokenFromMap(node);
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }

      for (final value in node.values) {
        final nested = _findTokenDeep(value);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    } else if (node is List) {
      for (final value in node) {
        final nested = _findTokenDeep(value);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    } else if (node is Map) {
      return _findTokenDeep(Map<String, dynamic>.from(node));
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _normalizeBarcode(String barcode) {
    return barcode.replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '').trim();
  }
}
