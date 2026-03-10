class ReceiveItemParams {
  const ReceiveItemParams({
    required this.itemId,
    required this.toLocationId,
    required this.quantity,
    required this.workerId,
  });

  final int itemId;
  final int toLocationId;
  final int quantity;
  final String workerId;
}
