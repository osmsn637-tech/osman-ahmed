class ExceptionEntity {
  const ExceptionEntity({
    required this.id,
    required this.itemName,
    required this.expectedLocation,
    required this.warehouseId,
    required this.status,
  });

  final int id;
  final String itemName;
  final String expectedLocation;
  final int warehouseId;
  final String status;

  bool get isOpen => status.toLowerCase() == 'open';
}
