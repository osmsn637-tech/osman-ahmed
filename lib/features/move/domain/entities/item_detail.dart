import 'location_stock.dart';

class ItemDetail {
  const ItemDetail({
    required this.barcode,
    required this.name,
    required this.stocks,
  });

  final String barcode;
  final String name;
  final List<LocationStock> stocks;
}
