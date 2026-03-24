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
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.persistedUser});

  final User? persistedUser;

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<User>> login(LoginParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    return Success<User?>(persistedUser);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }
}
