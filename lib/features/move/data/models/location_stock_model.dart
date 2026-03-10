import '../../domain/entities/location_stock.dart';

class LocationStockModel extends LocationStock {
  const LocationStockModel({
    required super.locationId,
    required super.locationName,
    required super.quantity,
  });

  factory LocationStockModel.fromJson(Map<String, dynamic> json) {
    return LocationStockModel(
      locationId: json['location_id'] as int,
      locationName: json['location_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}
