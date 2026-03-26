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

  test('submit strips 966 prefix before sending the worker number', () async {
    final session = SessionController();
    final repository = _FakeAuthRepository(
      user: const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000010',
        name: 'Worker',
        role: 'worker',
        phone: '512345678',
        zone: 'A',
      ),
    );
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(repository),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: session,
    );

    controller.usernameChanged('966512345678');
    controller.passwordChanged('x');
    await controller.submit();

    expect(repository.lastLoginParams, isNotNull);
    expect(repository.lastLoginParams!.phone, '512345678');
  });

  test('submit strips leading zero before sending the worker number', () async {
    final session = SessionController();
    final repository = _FakeAuthRepository(
      user: const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000011',
        name: 'Worker',
        role: 'worker',
        phone: '512345678',
        zone: 'A',
      ),
    );
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(repository),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: session,
    );

    controller.usernameChanged('0512345678');
    controller.passwordChanged('x');
    await controller.submit();

    expect(repository.lastLoginParams, isNotNull);
    expect(repository.lastLoginParams!.phone, '512345678');
  });

  test('submit strips both 966 and 0 when both are entered before 5', () async {
    final session = SessionController();
    final repository = _FakeAuthRepository(
      user: const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000012',
        name: 'Worker',
        role: 'worker',
        phone: '512345678',
        zone: 'A',
      ),
    );
    final controller = LoginFormController(
      loginUseCase: LoginUseCase(repository),
      errors: GlobalErrorController(),
      loading: GlobalLoadingController(),
      session: session,
    );

    controller.usernameChanged('9660512345678');
    controller.passwordChanged('x');
    await controller.submit();

    expect(repository.lastLoginParams, isNotNull);
    expect(repository.lastLoginParams!.phone, '512345678');
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.user});

  final User user;
  LoginParams? lastLoginParams;

  @override
  Future<Result<User>> login(LoginParams params) async {
    lastLoginParams = params;
    return Success<User>(user);
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
