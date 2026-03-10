import 'package:dio/dio.dart';

import '../constants/app_endpoints.dart';
import '../utils/result.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenSupplier,
    required this.tokenRefresher,
    required this.dio,
  });

  final Future<String?> Function() tokenSupplier;
  final Future<Result<void>> Function() tokenRefresher;
  final Dio dio;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isExternalLookupEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final existingAuth = options.headers['Authorization'];
    if (existingAuth is String && existingAuth.trim().isNotEmpty) {
      handler.next(options);
      return;
    }

    final token = await tokenSupplier();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRefresh(err)) {
      if (_isRefreshing) {
        return handler.reject(err);
      }
      _isRefreshing = true;
      final refreshResult = await tokenRefresher();
      _isRefreshing = false;

      if (refreshResult is Success<void>) {
        final clonedResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(clonedResponse);
      }
    }

    handler.next(err);
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) {
    final newOptions = requestOptions.copyWith(
      data: requestOptions.data,
      path: requestOptions.path,
      headers: requestOptions.headers,
      method: requestOptions.method,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );

    return dio.fetch<dynamic>(newOptions);
  }

  bool _shouldRefresh(DioException err) {
    final isUnauthorized = err.response?.statusCode == 401;
    final requestPath = err.requestOptions.path;
    final isAuthEndpoint = requestPath.contains(AppEndpoints.login) ||
        requestPath.contains(AppEndpoints.refresh) ||
        requestPath.contains(AppEndpoints.qeuMobileLogin) ||
        requestPath.contains('/v1/inventory/login');

    return isUnauthorized && !isAuthEndpoint;
  }

  bool _isExternalLookupEndpoint(String path) {
    return path.contains(AppEndpoints.qeuMobileLogin) ||
        path.contains('/v1/inventory/login');
  }
}
