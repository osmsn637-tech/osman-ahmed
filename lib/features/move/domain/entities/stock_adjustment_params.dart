class StockAdjustmentParams {
  const StockAdjustmentParams({
    required this.itemId,
    required this.warehouseId,
    required this.locationId,
    required this.locationBarcode,
    required this.systemQuantity,
    required this.actualQuantity,
    required this.workerId,
    this.note,
  });

  final int itemId;
  final String warehouseId;
  final String locationId;
  final String locationBarcode;
  final int systemQuantity;
  final int actualQuantity;
  final String workerId;
  final String? note;
}
