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
  const LoginFormState({this.username = '', this.password = '', this.isSubmitting = false});

  final String username;
  final String password;
  final bool isSubmitting;

  bool get isValid => username.isNotEmpty && password.isNotEmpty;

  LoginFormState copyWith({String? username, String? password, bool? isSubmitting}) => LoginFormState(
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
        _state = const LoginFormState();

  final LoginUseCase _loginUseCase;
  final GlobalErrorController _errors;
  final GlobalLoadingController _loading;
  final SessionController _session;
  final TokenRepository? _tokenRepository;

  LoginFormState _state;
  LoginFormState get state => _state;

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
      LoginParams(phone: _state.username, password: _state.password),
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
}
