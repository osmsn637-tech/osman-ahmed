import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/shared/widgets/role_guard.dart';

void main() {
  testWidgets('role guard allows reciver alias for inbound routes',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000005',
        name: 'Receiver Guard',
        role: 'reciver',
        phone: '966522222222',
        zone: 'Z03',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionController>.value(
        value: session,
        child: const MaterialApp(
          home: RoleGuard(
            allowedRoles: ['inbound'],
            child: Scaffold(body: Text('Inbound Allowed')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inbound Allowed'), findsOneWidget);
    expect(find.text('Access Denied'), findsNothing);
  });
}
