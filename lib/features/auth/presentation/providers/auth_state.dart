import '../../domain/entities/user.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  final bool isLoading;
  final User? user;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({bool? isLoading, User? user, String? errorMessage}) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );

  AuthState clearError() => copyWith(errorMessage: null);
}
