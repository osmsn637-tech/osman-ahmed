class Movement {
  const Movement({
    required this.barcode,
    required this.fromLocationId,
    required this.toLocationId,
    required this.quantity,
    this.movementId,
    this.movedAt,
  });

  final String barcode;
  final int fromLocationId;
  final int toLocationId;
  final int quantity;
  final int? movementId;
  final DateTime? movedAt;
}
