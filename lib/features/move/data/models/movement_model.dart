import '../../domain/entities/movement.dart';

class MovementModel extends Movement {
  const MovementModel({
    required super.barcode,
    required super.fromLocationId,
    required super.toLocationId,
    required super.quantity,
    super.movementId,
    super.movedAt,
  });

  factory MovementModel.fromJson(Map<String, dynamic> json) {
    return MovementModel(
      barcode: json['barcode'] as String,
      fromLocationId: json['from_location_id'] as int,
      toLocationId: json['to_location_id'] as int,
      quantity: (json['quantity'] as num).toInt(),
      movementId: json['id'] as int?,
      movedAt: json['moved_at'] != null ? DateTime.tryParse(json['moved_at'] as String) : null,
    );
  }
}
