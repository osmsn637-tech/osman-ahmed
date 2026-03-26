import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/login_params.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/domain/repositories/auth_repository.dart';
import 'package:wherehouse/features/auth/domain/usecases/login_usecase.dart';
import 'package:wherehouse/features/auth/presentation/pages/login_page.dart';
import 'package:wherehouse/features/auth/presentation/providers/login_form_provider.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/shared/providers/global_error_provider.dart';
import 'package:wherehouse/shared/providers/global_loading_provider.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';
import 'package:wherehouse/shared/widgets/global_loading_listener.dart';

class _PendingAuthRepository implements AuthRepository {
  _PendingAuthRepository(this.completer);

  final Completer<Result<User>> completer;

  @override
  Future<Result<User>> login(LoginParams params) => completer.future;

  @override
  Future<Result<User?>> loadPersistedSession() async {
    return const Success<User?>(null);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}

class _RecordingAuthRepository implements AuthRepository {
  final List<LoginParams> calls = <LoginParams>[];

  @override
  Future<Result<User>> login(LoginParams params) async {
    calls.add(params);
    return const Success<User>(
      User(
        id: '1',
        name: 'Worker',
        role: 'worker',
        phone: '0555555555',
        zone: 'Z01',
      ),
    );
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    return const Success<User?>(null);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}

void main() {
  testWidgets('login page shows branded app logo', (tester) async {
    final loginFormController = LoginFormController(
      loginUseCase: LoginUseCase(_RecordingAuthRepository()),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: SessionController(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GlobalLoadingController>.value(
            value: GlobalLoadingController(),
          ),
          ChangeNotifierProvider<LoginFormController>.value(
            value: loginFormController,
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: GlobalLoadingListener(
            child: LoginPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/app_icon_master.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'login submit shows one global loader and disables the form while pending',
      (tester) async {
    final completer = Completer<Result<User>>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete(
          const Success<User>(
            User(
              id: '1',
              name: 'Worker',
              role: 'worker',
              phone: '0555555555',
              zone: 'Z01',
            ),
          ),
        );
      }
    });

    final loading = GlobalLoadingController();
    final loginFormController = LoginFormController(
      loginUseCase: LoginUseCase(_PendingAuthRepository(completer)),
      errors: GlobalErrorController(),
      loading: loading,
      session: SessionController(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GlobalLoadingController>.value(value: loading),
          ChangeNotifierProvider<LoginFormController>.value(
            value: loginFormController,
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: GlobalLoadingListener(
            child: LoginPage(),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '0555555555');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(barriers.any((barrier) => barrier.dismissible == false), isTrue);
    expect(find.text('Sign In'), findsOneWidget);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    for (final field in fields) {
      expect(field.enabled, isFalse);
    }

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'logout clears stale credentials and keeps sign in disabled',
      (tester) async {
    final repository = _RecordingAuthRepository();
    final loading = GlobalLoadingController();
    final session = SessionController();
    final loginFormController = LoginFormController(
      loginUseCase: LoginUseCase(repository),
      errors: GlobalErrorController(),
      loading: loading,
      session: session,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GlobalLoadingController>.value(
            value: loading,
          ),
          ChangeNotifierProvider<LoginFormController>.value(
            value: loginFormController,
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: GlobalLoadingListener(
            child: LoginPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '0555555555');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.pump();

    final enabledBeforeReset = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(enabledBeforeReset.onPressed, isNotNull);

    session.setUser(
      const User(
        id: '1',
        name: 'Worker',
        role: 'worker',
        phone: '0555555555',
        zone: 'Z01',
      ),
    );
    await tester.pump();

    session.clear();
    await tester.pump();

    expect(find.text('0555555555'), findsNothing);
    expect(find.text('123456'), findsNothing);

    final buttonAfterReset = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(buttonAfterReset.onPressed, isNull);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
  });
}
