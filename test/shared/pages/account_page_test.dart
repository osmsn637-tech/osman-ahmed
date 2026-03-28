import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/core/config/app_environment_controller.dart';
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
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('account page shows normalized worker zone details',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000001',
        name: 'Worker One',
        role: 'worker',
        phone: '966500000000',
        zone: 'zone b',
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
    expect(find.text('WORKER'), findsWidgets);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
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
        zone: 'zone a',
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
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
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

    await scrollTo(tester, find.text('Change Password'));
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
      result:
          const Failure<void>(ValidationException('Wrong current password')),
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

    await scrollTo(tester, find.text('Change Password'));
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'old-secret');
    await tester.enterText(find.byType(TextField).at(1), 'new-secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong current password'), findsOneWidget);
  });

  testWidgets('sign out clears persisted auth through repository logout',
      (tester) async {
    final session = SessionController();
    final repository = _FakeAuthRepository();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000007',
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

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
    expect(session.state.isAuthenticated, isFalse);
  });

  testWidgets('account page shows and selects Urdu language option',
      (tester) async {
    final session = SessionController();
    final localeController = LocaleController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000008',
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
          ChangeNotifierProvider<LocaleController>.value(
              value: localeController),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    expect(find.text('اردو'), findsOneWidget);

    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    expect(localeController.locale.languageCode, 'ur');
  });

  testWidgets('account page keeps all language buttons on one line',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000010',
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
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    double buttonCenterY(String label) {
      final button = find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      return tester.getCenter(button).dy;
    }

    final arabicY = buttonCenterY('Arabic');
    final englishY = buttonCenterY('English');
    final urduY = buttonCenterY('اردو');

    expect(arabicY, closeTo(englishY, 0.01));
    expect(urduY, closeTo(englishY, 0.01));
  });

  testWidgets('change password dialog renders Urdu labels in Urdu locale',
      (tester) async {
    final session = SessionController();
    final repository = _FakeAuthRepository();
    final localeController = LocaleController()..setLocale('ur');
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000009',
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
          ChangeNotifierProvider<LocaleController>.value(
              value: localeController),
        ],
        child: const MaterialApp(
          locale: Locale('ur'),
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    await scrollTo(tester, find.text('پاس ورڈ تبدیل کریں'));
    await tester.tap(find.text('پاس ورڈ تبدیل کریں'));
    await tester.pumpAndSettle();

    expect(find.text('موجودہ پاس ورڈ'), findsOneWidget);
    expect(find.text('نیا پاس ورڈ'), findsOneWidget);
    expect(find.text('منسوخ کریں'), findsOneWidget);
    expect(find.text('پاس ورڈ اپ ڈیٹ کریں'), findsOneWidget);
  });

  testWidgets('five taps on the zone row opens the developer mode PIN dialog',
      (tester) async {
    final session = SessionController();
    final environmentController =
        _FakeAppEnvironmentController(AppEnvironment.production);
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000011',
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
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    final zoneRow = find.byKey(const Key('account-zone-row'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(zoneRow);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Developer Mode'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('correct developer mode PIN switches the app to dev mode',
      (tester) async {
    final session = SessionController();
    final environmentController =
        _FakeAppEnvironmentController(AppEnvironment.production);
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000012',
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
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    final zoneRow = find.byKey(const Key('account-zone-row'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(zoneRow);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '564238');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Switch'));
    await tester.pumpAndSettle();

    expect(environmentController.environment, AppEnvironment.development);
  });

  testWidgets('wrong developer mode PIN keeps the app in production mode',
      (tester) async {
    final session = SessionController();
    final environmentController =
        _FakeAppEnvironmentController(AppEnvironment.production);
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000013',
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
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    final zoneRow = find.byKey(const Key('account-zone-row'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(zoneRow);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '111111');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Switch'));
    await tester.pumpAndSettle();

    expect(environmentController.environment, AppEnvironment.production);
    expect(find.text('Incorrect PIN'), findsOneWidget);
  });

  testWidgets(
      'correct developer mode PIN switches back to production when already in dev mode',
      (tester) async {
    final session = SessionController();
    final environmentController =
        _FakeAppEnvironmentController(AppEnvironment.development);
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000014',
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
          ChangeNotifierProvider<AppEnvironmentController>.value(
            value: environmentController,
          ),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
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

    final zoneRow = find.byKey(const Key('account-zone-row'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(zoneRow);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '564238');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Switch'));
    await tester.pumpAndSettle();

    expect(environmentController.environment, AppEnvironment.production);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.result = const Success<void>(null)});

  final Result<void> result;
  String? currentPassword;
  String? newPassword;
  int logoutCalls = 0;

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
    logoutCalls += 1;
    return const Success<void>(null);
  }
}

class _FakeAppEnvironmentController extends AppEnvironmentController {
  _FakeAppEnvironmentController(AppEnvironment environment)
      : _environment = environment;

  AppEnvironment _environment;

  @override
  AppEnvironment get environment => _environment;

  @override
  Future<void> toggleEnvironment() async {
    _environment = _environment == AppEnvironment.production
        ? AppEnvironment.development
        : AppEnvironment.production;
    notifyListeners();
  }
}
