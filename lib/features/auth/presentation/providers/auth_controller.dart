import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/login_params.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'session_provider.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
    required SessionController session,
  })
      : _loginUseCase = loginUseCase,
        _authRepository = authRepository,
        _session = session;

  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;
  final SessionController _session;
  bool _initialized = false;
  AuthState _state = const AuthState();

  AuthState get state => _state;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await loadPersisted();
  }

  Future<void> loadPersisted() async {
    final result = await _authRepository.loadPersistedSession();
    switch (result) {
      case Success<User?>(data: final user):
        if (user != null) {
          _session.setUser(user);
          _setState(state.copyWith(user: user));
        }
      case Failure<User?>(error: _):
        await _authRepository.logout();
        _session.clear();
        _setState(const AuthState());
    }
  }

  Future<void> login({required String phone, required String password}) async {
    if (state.isLoading) return;
    _setState(state.copyWith(isLoading: true, errorMessage: null));

    final result = await _loginUseCase.execute(LoginParams(phone: phone, password: password));
    switch (result) {
      case Success<User>(data: final user):
        _session.setUser(user);
        _setState(state.copyWith(isLoading: false, user: user, errorMessage: null));
      case Failure<User>(error: final error):
        final message = _messageFor(error);
        _setState(state.copyWith(isLoading: false, errorMessage: message));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _session.clear();
    _setState(const AuthState());
  }

  void forceLogout() {
    _authRepository.logout();
    _session.clear();
    _setState(const AuthState());
  }

  String _messageFor(Object error) {
    if (error is ValidationException) return error.message;
    if (error is UnauthorizedException || error is AuthExpiredException) return 'Session expired. Please login again.';
    if (error is NetworkException) return 'Network error. Check connection.';
    if (error is AppException) return error.message;
    return 'Unexpected error occurred';
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
