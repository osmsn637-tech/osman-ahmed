class MoveItemParams {
  const MoveItemParams({
    required this.itemId,
    required this.barcode,
    required this.fromLocationId,
    required this.toLocationId,
    required this.quantity,
    required this.workerId,
  });

  final int itemId;
  final String barcode;
  final int fromLocationId;
  final int toLocationId;
  final int quantity;
  final String workerId;
}
