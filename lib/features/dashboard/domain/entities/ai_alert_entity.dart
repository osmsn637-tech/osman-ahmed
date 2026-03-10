class AiAlertEntity {
  const AiAlertEntity({
    required this.id,
    required this.itemId,
    required this.locationId,
    required this.riskScore,
    required this.alertType,
    required this.message,
    required this.createdAt,
    required this.resolved,
  });

  final String id;
  final int itemId;
  final int locationId;
  final int riskScore;
  final String alertType;
  final String message;
  final DateTime createdAt;
  final bool resolved;

  bool get isHighRisk => riskScore >= 70;
}
