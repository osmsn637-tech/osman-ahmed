class CycleCountItem {
  const CycleCountItem({
    required this.itemId,
    required this.name,
    required this.expectedQuantity,
    this.actualQuantity,
  });

  final int itemId;
  final String name;
  final int expectedQuantity;
  final int? actualQuantity;

  CycleCountItem copyWith({int? actualQuantity}) => CycleCountItem(
        itemId: itemId,
        name: name,
        expectedQuantity: expectedQuantity,
        actualQuantity: actualQuantity ?? this.actualQuantity,
      );

  int get difference => (actualQuantity ?? 0) - expectedQuantity;
  bool get hasDifference => actualQuantity != null && actualQuantity != expectedQuantity;
}
