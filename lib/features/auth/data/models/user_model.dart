import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, required super.name, required super.role, required super.phone, required super.zone});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = _extractUserSource(json);
    final rawId = _readRawId(source ?? json);
    final resolvedJson = source ?? json;
    final parsedId = _readId(rawId);
    if (parsedId == null) {
      throw const FormatException('Invalid user id in response');
    }

    final rawPhone = resolvedJson['phone'] ?? json['phone'];
    final phone = rawPhone is String ? rawPhone : rawPhone?.toString() ?? '';
    final rawZone = resolvedJson['zone'] ?? json['zone'];
    final zone = rawZone is String ? rawZone : rawZone?.toString() ?? '';

    return UserModel(
      id: parsedId,
      name: resolvedJson['name']?.toString() ?? json['name']?.toString() ?? '',
      role: resolvedJson['role']?.toString() ?? json['role']?.toString() ?? '',
      phone: phone,
      zone: zone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
        'zone': zone,
      };

  static Object? _readRawId(Map<String, dynamic> json) {
    const candidateKeys = ['id', 'user_id', 'userId', 'uid', '_id', 'uuid', 'user-id'];

    Object? value;
    for (final key in candidateKeys) {
      value = json[key];
      if (value != null) return value;
    }

    final nestedUser = json['user'];
    if (nestedUser is Map<String, dynamic>) {
      for (final key in candidateKeys) {
        value = nestedUser[key];
        if (value != null) return value;
      }
    }

    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      for (final key in candidateKeys) {
        value = nestedData[key];
        if (value != null) return value;
      }

      final nestedDataUser = nestedData['user'];
      if (nestedDataUser is Map<String, dynamic>) {
        for (final key in candidateKeys) {
          value = nestedDataUser[key];
          if (value != null) return value;
        }
      }
    }

    for (final valueObj in json.values) {
      if (valueObj is Map<String, dynamic>) {
        for (final key in candidateKeys) {
          final nestedValue = valueObj[key];
          if (nestedValue != null) return nestedValue;
        }
      }
    }

    return null;
  }

  static String? _readId(Object? value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    }

    if (value is int) return value.toString();
    if (value is num) return value.toInt().toString();
    final fallback = value.toString().trim();
    if (fallback.isEmpty) return null;
    return fallback;
  }

  static Map<String, dynamic>? _extractUserSource(Map<String, dynamic> json) {
    final userObject = json['user'];
    if (userObject is Map<String, dynamic>) return userObject;

    final dataObject = json['data'];
    if (dataObject is Map<String, dynamic>) {
      final nestedUser = dataObject['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
    }

    return null;
  }
}
