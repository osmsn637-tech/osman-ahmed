import '../../../../core/auth/models/auth_tokens.dart';
import '../models/user_model.dart';

class LoginResponseDto {
  const LoginResponseDto({required this.user, required this.tokens});

  final UserModel user;
  final AuthTokens tokens;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    return LoginResponseDto(
      user: UserModel.fromJson(
        root['user'] is Map<String, dynamic>
            ? root['user'] as Map<String, dynamic>
            : root,
      ),
      tokens: AuthTokens(
        accessToken: _extractToken(root, ['access_token', 'accessToken', 'token', 'access']),
        refreshToken: _extractToken(root, ['refresh_token', 'refreshToken', 'refresh']),
      ),
    );
  }

  static String _extractToken(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }
}
