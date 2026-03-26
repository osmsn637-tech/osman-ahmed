import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/auth/token_repository.dart';
import '../../../../shared/providers/global_error_provider.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../domain/entities/login_params.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import 'session_provider.dart';

class LoginFormState {
  const LoginFormState({
    this.username = '',
    this.password = '',
    this.isSubmitting = false,
  });

  final String username;
  final String password;
  final bool isSubmitting;

  bool get isValid => username.isNotEmpty && password.isNotEmpty;

  LoginFormState copyWith({
    String? username,
    String? password,
    bool? isSubmitting,
  }) => LoginFormState(
        username: username ?? this.username,
        password: password ?? this.password,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class LoginFormController extends ChangeNotifier {
  LoginFormController({
    required LoginUseCase loginUseCase,
    required GlobalErrorController errors,
    required GlobalLoadingController loading,
    required SessionController session,
    TokenRepository? tokenRepository,
  })  : _loginUseCase = loginUseCase,
        _errors = errors,
        _loading = loading,
        _session = session,
        _tokenRepository = tokenRepository,
        _state = const LoginFormState() {
    _wasAuthenticated = _session.state.isAuthenticated;
    _session.addListener(_handleSessionChanged);
  }

  final LoginUseCase _loginUseCase;
  final GlobalErrorController _errors;
  final GlobalLoadingController _loading;
  final SessionController _session;
  final TokenRepository? _tokenRepository;

  LoginFormState _state;
  late bool _wasAuthenticated;
  LoginFormState get state => _state;

  void _handleSessionChanged() {
    final isAuthenticated = _session.state.isAuthenticated;
    if (_wasAuthenticated && !isAuthenticated) {
      reset();
    }
    _wasAuthenticated = isAuthenticated;
  }

  void usernameChanged(String value) {
    if (_state.username == value) return;
    final wasValid = _state.isValid;
    _state = _state.copyWith(username: value);
    if (wasValid != _state.isValid) notifyListeners();
  }

  void passwordChanged(String value) {
    if (_state.password == value) return;
    final wasValid = _state.isValid;
    _state = _state.copyWith(password: value);
    if (wasValid != _state.isValid) notifyListeners();
  }

  void reset() {
    if (_state.username.isEmpty &&
        _state.password.isEmpty &&
        !_state.isSubmitting) {
      return;
    }

    _state = const LoginFormState();
    notifyListeners();
  }

  Future<void> submit() async {
    if (!_state.isValid || _state.isSubmitting) return;

    _state = _state.copyWith(isSubmitting: true);
    notifyListeners();

    await _loading.track(_handleLogin());

    _state = _state.copyWith(isSubmitting: false);
    notifyListeners();
  }

  Future<void> _handleLogin() async {
    final result = await _loginUseCase.execute(
      LoginParams(
        phone: _normalizePhoneForSubmit(_state.username),
        password: _state.password,
      ),
    );

    switch (result) {
      case Success<User>(data: final user):
        final accessToken = await _tokenRepository?.getAccessToken();
        _session.setUser(user, accessToken: accessToken);
      case Failure<User>(error: final error):
        if (error is AppException) {
          _errors.showError(error);
        } else {
          _errors.showError(const UnknownException('Unknown error'));
        }
    }
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChanged);
    super.dispose();
  }

  static String _normalizePhoneForSubmit(String rawValue) {
    var normalized = rawValue.replaceAll(RegExp(r'\D'), '');
    if (normalized.startsWith('00') && normalized.length > 2) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('966') && normalized.length > 3) {
      normalized = normalized.substring(3);
    }
    if (normalized.startsWith('0') && normalized.length > 1) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
