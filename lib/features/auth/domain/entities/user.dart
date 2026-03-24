class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.zone,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String zone;

  String get canonicalRole => canonicalizeRole(role);

  bool get isWorker => canonicalRole == 'worker';
  bool get isSupervisor => canonicalRole == 'supervisor';
  bool get isInbound => canonicalRole == 'inbound';

  static String canonicalizeRole(String role) {
    final normalized = role
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    return switch (normalized) {
      'admin' => 'supervisor',
      'receiver' || 'reciver' => 'inbound',
      'putaway operator' || 'putaway opreater' => 'worker',
      _ => normalized,
    };
  }
}
