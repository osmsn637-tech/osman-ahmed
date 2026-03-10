import '../../domain/entities/item_detail.dart';
import 'location_stock_model.dart';

class ItemDetailModel extends ItemDetail {
  const ItemDetailModel({required super.barcode, required super.name, required super.stocks});

  factory ItemDetailModel.fromJson(Map<String, dynamic> json) {
    final stocksJson = json['stocks'] as List<dynamic>? ?? [];
    final stocks = stocksJson.map((e) => LocationStockModel.fromJson(e as Map<String, dynamic>)).toList();
    return ItemDetailModel(
      barcode: json['barcode'] as String,
      name: json['name'] as String? ?? '',
      stocks: stocks,
    );
  }
}
