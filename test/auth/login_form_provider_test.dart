import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/login_params.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/domain/repositories/auth_repository.dart';
import 'package:wherehouse/features/auth/domain/usecases/login_usecase.dart';
import 'package:wherehouse/features/auth/presentation/providers/login_form_provider.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/shared/providers/global_error_provider.dart';
import 'package:wherehouse/shared/providers/global_loading_provider.dart';

void main() {
  test('mock login assigns inbound role for inbound account', () async {
    final session = SessionController();
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(
        _FakeAuthRepository(
          user: const User(
            id: '2bcf9d5d-1234-4f1d-8f6d-000000000001',
            name: 'Inbound',
            role: 'inbound',
            phone: '2220000000',
            zone: 'Z',
          ),
        ),
      ),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: session,
    );

    controller.usernameChanged('2220000000');
    controller.passwordChanged('x');
    await controller.submit();

    expect(session.state.user?.role, 'inbound');
  });

  test('mock login assigns supervisor role for supervisor account', () async {
    final session = SessionController();
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(
        _FakeAuthRepository(
          user: const User(
            id: '2bcf9d5d-1234-4f1d-8f6d-000000000002',
            name: 'Supervisor',
            role: 'supervisor',
            phone: '9990000000',
            zone: 'Z',
          ),
        ),
      ),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: session,
    );

    controller.usernameChanged('9990000000');
    controller.passwordChanged('x');
    await controller.submit();

    expect(session.state.user?.role, 'supervisor');
  });

  test('notifies listeners only when login form validity changes', () {
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(
        _FakeAuthRepository(
          user: const User(
            id: '2bcf9d5d-1234-4f1d-8f6d-000000000003',
            name: 'Form',
            role: 'worker',
            phone: '1',
            zone: 'Z',
          ),
        ),
      ),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: SessionController(),
    );

    var notificationCount = 0;
    controller.addListener(() => notificationCount++);

    controller.usernameChanged('1');
    controller.usernameChanged('12');
    expect(notificationCount, 0);

    controller.passwordChanged('x');
    expect(notificationCount, 1);

    controller.passwordChanged('xy');
    expect(notificationCount, 1);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.user});

  final User user;

  @override
  Future<Result<User>> login(LoginParams params) async {
    return Success<User>(user);
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
