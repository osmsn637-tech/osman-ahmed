import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/auth/domain/entities/login_params.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/domain/repositories/auth_repository.dart';
import 'package:wherehouse/features/auth/domain/usecases/login_usecase.dart';
import 'package:wherehouse/features/auth/presentation/providers/auth_controller.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';

void main() {
  test('loadPersisted pushes restored user into session', () async {
    const user = User(
      id: 'u1',
      name: 'Worker',
      role: 'worker',
      phone: '555',
      zone: 'A1',
    );
    final repository = _FakeAuthRepository(persistedUser: user);
    final session = SessionController();
    final controller = AuthController(
      loginUseCase: LoginUseCase(repository),
      authRepository: repository,
      session: session,
    );

    await controller.loadPersisted();

    expect(controller.state.user, user);
    expect(session.state.user, user);
    expect(session.state.isAuthenticated, isTrue);
  });

  test('late failed persisted restore does not clear a fresh login session', () async {
    const persistedFailure = FormatException('bad persisted user');
    const loggedInUser = User(
      id: 'u2',
      name: 'Fresh Worker',
      role: 'worker',
      phone: '534517558',
      zone: 'A',
    );
    final repository = _FakeAuthRepository(
      persistedLoadCompleter: Completer<Result<User?>>(),
      loginResult: const Success<User>(loggedInUser),
    );
    final session = SessionController();
    final controller = AuthController(
      loginUseCase: LoginUseCase(repository),
      authRepository: repository,
      session: session,
    );

    final loadFuture = controller.loadPersisted();
    await controller.login(phone: '534517558', password: 'secret');

    expect(session.state.user, loggedInUser);
    expect(session.state.isAuthenticated, isTrue);

    repository.persistedLoadCompleter!.complete(
      const Failure<User?>(persistedFailure),
    );
    await loadFuture;

    expect(session.state.user, loggedInUser);
    expect(session.state.isAuthenticated, isTrue);
    expect(controller.state.user, loggedInUser);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.persistedUser,
    this.persistedLoadCompleter,
    this.loginResult,
  });

  final User? persistedUser;
  final Completer<Result<User?>>? persistedLoadCompleter;
  final Result<User>? loginResult;

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<User>> login(LoginParams params) async {
    return loginResult ?? (throw UnimplementedError());
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    if (persistedLoadCompleter != null) {
      return persistedLoadCompleter!.future;
    }
    return Success<User?>(persistedUser);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}
