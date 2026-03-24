import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/inbound_entities.dart';

class InboundRemoteDataSource {
  InboundRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Result<InboundReceiptScanResult>> scanReceipt(String barcode) {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      return Future.value(Failure<InboundReceiptScanResult>(
          ArgumentError('Barcode must not be empty.')));
    }
    return _client.get<InboundReceiptScanResult>(
      AppEndpoints.inboundReceiptScanByPo,
      queryParameters: {'po_number': normalized},
      parser: (data) =>
          _parseReceiptScanResult(data, fallbackBarcode: normalized),
    );
  }

  Future<Result<InboundReceipt>> getReceipt(String receiptId) {
    return _client.get<InboundReceipt>(
      AppEndpoints.inboundReceiptDetail(receiptId),
      parser: _parseReceipt,
    );
  }

  Future<Result<InboundReceipt>> startReceipt(String receiptId) {
    return _client.post<InboundReceipt>(
      AppEndpoints.inboundReceiptStart(receiptId),
      parser: _parseReceipt,
    );
  }

  Future<Result<InboundReceiptItem>> scanReceiptItem({
    required String receiptId,
    required String barcode,
  }) {
    return _client.post<InboundReceiptItem>(
      AppEndpoints.inboundReceiptScanItem(receiptId),
      data: {'barcode': barcode.trim()},
      parser: _parseReceiptItem,
    );
  }

  Future<Result<InboundReceipt>> confirmReceiptItem({
    required String receiptId,
    required String itemId,
    required int quantity,
    required DateTime expirationDate,
  }) {
    return _client.post<InboundReceipt>(
      AppEndpoints.inboundReceiptItemConfirm(itemId),
      data: {
        'receiptId': receiptId,
        'quantity': quantity,
        'expiration_date': expirationDate.toIso8601String(),
      },
      parser: _parseReceipt,
    );
  }

  Map<String, Object?> _asMap(dynamic data) {
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    return const <String, Object?>{};
  }

  String _firstNonEmptyString(Iterable<Object?> values) {
    for (final value in values) {
      final normalized = switch (value) {
        final String stringValue => stringValue.trim(),
        final num numberValue => numberValue.toString().trim(),
        _ => '',
      };
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  int _firstInt(Iterable<Object?> values, {int fallback = 0}) {
    for (final value in values) {
      final normalized = switch (value) {
        final int intValue => intValue,
        final num numValue => numValue.toInt(),
        final String stringValue => int.tryParse(stringValue.trim()),
        _ => null,
      };
      if (normalized != null) return normalized;
    }
    return fallback;
  }

  InboundReceiptScanResult _parseReceiptScanResult(
    dynamic data, {
    required String fallbackBarcode,
  }) {
    final map = _asMap(data);
    final rawItems = map['items'] ?? map['products'];
    final items = rawItems is List
        ? rawItems
            .map((item) => _parseReceiptItem(item))
            .toList(growable: false)
        : const <InboundReceiptItem>[];
    return InboundReceiptScanResult(
      barcode: _firstNonEmptyString([map['barcode'], fallbackBarcode]),
      receiptId: _firstNonEmptyString([map['receiptId'], map['id']]),
      poNumber: _firstNonEmptyString([
        map['poNumber'],
        map['po_number'],
        map['po'],
        fallbackBarcode,
      ]),
      status: _firstNonEmptyString([map['status'], 'pending']),
      items: items,
    );
  }

  InboundReceipt _parseReceipt(dynamic data) {
    final map = _asMap(data);
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
            .map((item) => _parseReceiptItem(item))
            .toList(growable: false)
        : const <InboundReceiptItem>[];
    return InboundReceipt(
      id: _firstNonEmptyString([map['id']]),
      poNumber: _firstNonEmptyString([
        map['poNumber'],
        map['po_number'],
        map['po'],
      ]),
      status: _firstNonEmptyString([map['status'], 'pending']),
      items: items,
    );
  }

  InboundReceiptItem _parseReceiptItem(dynamic data) {
    final map = _asMap(data);
    final product = _asMap(map['product']);
    final imageUrl = _firstNonEmptyString([
      map['item_image_url'],
      map['productImage'],
      map['product_image'],
      map['imageUrl'],
      map['image_url'],
      map['image'],
      product['item_image_url'],
      product['productImage'],
      product['product_image'],
      product['imageUrl'],
      product['image_url'],
      product['image'],
    ]);
    return InboundReceiptItem(
      id: _firstNonEmptyString([map['id'], map['itemId'], product['id']]),
      itemName: _firstNonEmptyString([
        map['itemName'],
        map['product_name'],
        map['productName'],
        map['name'],
        product['product_name'],
        product['productName'],
        product['name'],
      ]),
      barcode: _firstNonEmptyString([
        map['barcode'],
        map['product_barcode'],
        map['sku'],
        product['barcode'],
      ]),
      expectedQuantity: _firstInt([
        map['expectedQuantity'],
        map['expected_quantity'],
        map['receiptQuantity'],
        map['receipt_quantity'],
        map['quantity'],
      ]),
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      receivedQuantity: _firstInt([
        map['receivedQuantity'],
        map['received_quantity'],
      ]),
      expirationDate: _parseDateTime(
        map['expirationDate'] ??
            map['expiration_date'] ??
            map['expiryDate'] ??
            map['expiry_date'],
      ),
    );
  }

  DateTime? _parseDateTime(Object? value) {
    final raw = switch (value) {
      final String stringValue => stringValue.trim(),
      _ => '',
    };
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
