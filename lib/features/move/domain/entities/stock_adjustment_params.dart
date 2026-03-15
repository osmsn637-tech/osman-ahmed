class StockAdjustmentParams {
  const StockAdjustmentParams({
    required this.itemId,
    required this.locationId,
    required this.newQuantity,
    required this.reason,
    required this.workerId,
    this.note,
  });

  final int itemId;
  final int locationId;
  final int newQuantity;
  final String reason;
  final String workerId;
  final String? note;
}
