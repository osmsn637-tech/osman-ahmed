import '../storage/secure_token_storage.dart';

class TokenRepository {
  TokenRepository(this._storage);

  final SecureTokenStorage _storage;

  Future<String?> getAccessToken() => _storage.readAccessToken();
  Future<String?> getRefreshToken() => _storage.readRefreshToken();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) {
    return _storage.persistTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> saveUser(Map<String, dynamic> user) => _storage.persistUser(user);

  Future<Map<String, dynamic>?> readUser() => _storage.readUser();

  Future<void> clear() => _storage.clear();
}
