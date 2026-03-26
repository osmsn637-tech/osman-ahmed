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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<User>> login(LoginParams params) async {
    return Failure<User>(Exception('unused in this test'));
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
  testWidgets('login page avoids rebuild-restarting intro tween', (
    tester,
  ) async {
    final loginFormController = LoginFormController(
      loginUseCase: LoginUseCase(_FakeAuthRepository()),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: SessionController(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginFormController>.value(
            value: loginFormController,
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
