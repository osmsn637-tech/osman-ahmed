class ItemLocationEntity {
  const ItemLocationEntity({
    required this.locationId,
    required this.zone,
    required this.type,
    required this.code,
    required this.quantity,
  });

  final String locationId;
  final String zone;
  final String type; // shelf, bulk, or ground
  final String code;
  final int quantity;

  bool get isShelf => type.toLowerCase() == 'shelf';
  bool get isBulk => type.toLowerCase() == 'bulk';
  bool get isGround => type.toLowerCase() == 'ground';
}
