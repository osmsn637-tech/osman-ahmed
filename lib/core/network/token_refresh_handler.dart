import 'package:dio/dio.dart';

import '../constants/app_endpoints.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../storage/secure_token_storage.dart';
import '../utils/result.dart';

class TokenRefreshHandler {
  TokenRefreshHandler({
    required String baseUrl,
    required ErrorMapper errorMapper,
    required SecureTokenStorage tokenStorage,
    required void Function(String message) logger,
  })  : _errorMapper = errorMapper,
        _tokenStorage = tokenStorage,
        _logger = logger,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            contentType: 'application/json',
          ),
        );

  final Dio _dio;
  final ErrorMapper _errorMapper;
  final SecureTokenStorage _tokenStorage;
  final void Function(String message) _logger;

  Future<Result<void>> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const Failure<void>(UnauthorizedException('Refresh token missing'));
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final accessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String? ?? refreshToken;

      if (accessToken == null || accessToken.isEmpty) {
        return const Failure<void>(ServerException('Invalid refresh response'));
      }

      await _tokenStorage.persistTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      return const Success<void>(null);
    } catch (error, stackTrace) {
      final mapped = _errorMapper.map(error);
      _logger('Token refresh failed: $mapped\n$stackTrace');
      return Failure<void>(mapped);
    }
  }
}
