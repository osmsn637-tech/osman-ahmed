class AdjustmentTaskLocationScan {
  const AdjustmentTaskLocationScan({
    required this.locationId,
    required this.locationCode,
    required this.products,
  });

  final String locationId;
  final String locationCode;
  final List<AdjustmentTaskProduct> products;

  factory AdjustmentTaskLocationScan.fromMap(Map<String, dynamic> data) {
    final rawProducts = data['products'];
    return AdjustmentTaskLocationScan(
      locationId: _readString(data['locationId'] ?? data['location_id']),
      locationCode: _readString(data['locationCode'] ?? data['location_code']),
      products: rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map(
                (entry) => AdjustmentTaskProduct.fromMap(
                  Map<String, Object?>.from(entry),
                ),
              )
              .toList(growable: false)
          : const <AdjustmentTaskProduct>[],
    );
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  @override
  bool operator ==(Object other) {
    return other is AdjustmentTaskLocationScan &&
        other.locationId == locationId &&
        other.locationCode == locationCode &&
        _listEquals(other.products, products);
  }

  @override
  int get hashCode => Object.hash(locationId, locationCode, Object.hashAll(products));
}

class AdjustmentTaskProduct {
  const AdjustmentTaskProduct({
    required this.adjustmentItemId,
    required this.productId,
    required this.productName,
    required this.systemQuantity,
    required this.counted,
    this.productImage,
    this.batchNumber,
    this.expiryDate,
  });

  final String adjustmentItemId;
  final String productId;
  final String productName;
  final String? productImage;
  final int systemQuantity;
  final String? batchNumber;
  final String? expiryDate;
  final bool counted;

  AdjustmentTaskProduct copyWith({
    String? adjustmentItemId,
    String? productId,
    String? productName,
    Object? productImage = _sentinel,
    int? systemQuantity,
    Object? batchNumber = _sentinel,
    Object? expiryDate = _sentinel,
    bool? counted,
  }) {
    return AdjustmentTaskProduct(
      adjustmentItemId: adjustmentItemId ?? this.adjustmentItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage == _sentinel ? this.productImage : productImage as String?,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      batchNumber: batchNumber == _sentinel ? this.batchNumber : batchNumber as String?,
      expiryDate: expiryDate == _sentinel ? this.expiryDate : expiryDate as String?,
      counted: counted ?? this.counted,
    );
  }

  factory AdjustmentTaskProduct.fromMap(Map<String, Object?> data) {
    final adjustmentItemId = _readString(
      data['adjustmentItemId'] ??
          data['adjustment_item_id'] ??
          data['id'] ??
          data['itemId'] ??
          data['item_id'],
    );

    return AdjustmentTaskProduct(
      adjustmentItemId: adjustmentItemId,
      productId: _readString(
        data['productId'] ??
            data['product_id'] ??
            data['itemId'] ??
            data['item_id'] ??
            data['barcode'],
      ),
      productName: _readString(
        data['productName'] ??
            data['product_name'] ??
            data['itemName'] ??
            data['item_name'],
      ),
      productImage: _nullableString(
        data['productImage'] ??
            data['product_image'] ??
            data['image'] ??
            data['image_url'],
      ),
      systemQuantity: _readInt(
        data['systemQuantity'] ?? data['system_quantity'] ?? data['quantity'],
      ),
      batchNumber: _nullableString(data['batchNumber'] ?? data['batch_number']),
      expiryDate: _nullableString(data['expiryDate'] ?? data['expiry_date']),
      counted: data['counted'] == true,
    );
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  bool operator ==(Object other) {
    return other is AdjustmentTaskProduct &&
        other.adjustmentItemId == adjustmentItemId &&
        other.productId == productId &&
        other.productName == productName &&
        other.productImage == productImage &&
        other.systemQuantity == systemQuantity &&
        other.batchNumber == batchNumber &&
        other.expiryDate == expiryDate &&
        other.counted == counted;
  }

  @override
  int get hashCode => Object.hash(
        adjustmentItemId,
        productId,
        productName,
        productImage,
        systemQuantity,
        batchNumber,
        expiryDate,
        counted,
      );
}

const Object _sentinel = Object();

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
