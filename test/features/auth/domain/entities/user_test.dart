import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';

void main() {
  const baseUser = User(
    id: '2bcf9d5d-1234-4f1d-8f6d-000000000099',
    name: 'Alias User',
    role: 'worker',
    phone: '5000000000',
    zone: 'Z01',
  );

  User userWithRole(String role) => User(
        id: baseUser.id,
        name: baseUser.name,
        role: role,
        phone: baseUser.phone,
        zone: baseUser.zone,
      );

  test('reciver and receiver aliases are treated as inbound', () {
    expect(userWithRole('reciver').isInbound, isTrue);
    expect(userWithRole('receiver').isInbound, isTrue);
    expect(userWithRole('reciver').isWorker, isFalse);
  });

  test('putaway operator aliases are treated as worker', () {
    expect(userWithRole('putaway opreater').isWorker, isTrue);
    expect(userWithRole('putaway operator').isWorker, isTrue);
    expect(userWithRole('putaway_operator').isWorker, isTrue);
    expect(userWithRole('putaway-operator').isWorker, isTrue);
    expect(userWithRole('putaway operator').isInbound, isFalse);
  });
}
