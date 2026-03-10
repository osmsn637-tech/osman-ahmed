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

  bool get isWorker => role.toLowerCase() == 'worker';
  bool get isSupervisor => role.toLowerCase() == 'supervisor' || role.toLowerCase() == 'admin';
  bool get isInbound => role.toLowerCase() == 'inbound';
}
