class ItemLocationEntity {
  const ItemLocationEntity({
    required this.locationId,
    required this.zone,
    required this.type,
    required this.code,
    required this.quantity,
  });

  final int locationId;
  final String zone;
  final String type; // shelf or bulk
  final String code;
  final int quantity;

  bool get isShelf => type.toLowerCase() == 'shelf';
  bool get isBulk => type.toLowerCase() == 'bulk';
}
