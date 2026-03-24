import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/core/errors/app_exception.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/domain/entities/login_params.dart';
import 'package:wherehouse/features/auth/domain/repositories/auth_repository.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/shared/pages/account_page.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';

void main() {
  testWidgets('account page does not show copy action or zone details',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000001',
        name: 'Worker One',
        role: 'worker',
        phone: '966500000000',
        zone: 'Z01',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _FakeAuthRepository()),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy_rounded), findsNothing);
    expect(find.text('966500000000'), findsOneWidget);
    expect(find.text('PUTAWAY'), findsWidgets);
    expect(find.text('WORKER'), findsNothing);
    expect(find.text('Zone Z01'), findsNothing);
    expect(find.text('Z01'), findsNothing);
    expect(find.text('Zone'), findsNothing);
  });

  testWidgets('account page shows inbound label for reciver alias',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000004',
        name: 'Receiver One',
        role: 'reciver',
        phone: '966511111111',
        zone: 'Z02',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _FakeAuthRepository()),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('INBOUND'), findsWidgets);
    expect(find.text('RECIVER'), findsNothing);
    expect(find.text('Zone Z02'), findsNothing);
    expect(find.text('Z02'), findsNothing);
  });

  testWidgets('change password button submits current and new password',
      (tester) async {
    final session = SessionController();
    final repository = _FakeAuthRepository();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000005',
        name: 'Worker One',
        role: 'worker',
        phone: '966500000000',
        zone: 'Z01',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: repository),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'old-secret');
    await tester.enterText(find.byType(TextField).at(1), 'new-secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pumpAndSettle();

    expect(repository.currentPassword, 'old-secret');
    expect(repository.newPassword, 'new-secret');
    expect(find.text('Password updated successfully'), findsOneWidget);
  });

  testWidgets('change password button shows repository error message',
      (tester) async {
    final session = SessionController();
    final repository = _FakeAuthRepository(
      result: const Failure<void>(ValidationException('Wrong current password')),
    );
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000006',
        name: 'Worker One',
        role: 'worker',
        phone: '966500000000',
        zone: 'Z01',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: repository),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'old-secret');
    await tester.enterText(find.byType(TextField).at(1), 'new-secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong current password'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.result = const Success<void>(null)});

  final Result<void> result;
  String? currentPassword;
  String? newPassword;

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    this.currentPassword = currentPassword;
    this.newPassword = newPassword;
    return result;
  }

  @override
  Future<Result<User>> login(LoginParams params) {
    throw UnimplementedError();
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    return const Success<User?>(null);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}
