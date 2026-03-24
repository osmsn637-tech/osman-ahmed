import 'package:dio/dio.dart';

import '../errors/error_mapper.dart';
import '../errors/app_exception.dart';
import '../auth/token_repository.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'token_refresh_handler.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    required bool enableLogging,
    required TokenRepository tokenRepository,
    required TokenRefreshHandler tokenRefreshHandler,
    required ErrorMapper errorMapper,
    required void Function() onRefreshFailure,
    required void Function(String) logger,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.addAll([
      AuthInterceptor(
        tokenSupplier: tokenRepository.getAccessToken,
        tokenRefresher: () => tokenRefreshHandler.refresh(),
        dio: dio,
      ),
      ErrorInterceptor(
        errorMapper: errorMapper,
        onError: (error) {
          if (error is AuthExpiredException) {
            onRefreshFailure();
          }
        },
      ),
      if (enableLogging)
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => logger(obj.toString()),
        ),
    ]);
  }

  final Dio dio;
}
