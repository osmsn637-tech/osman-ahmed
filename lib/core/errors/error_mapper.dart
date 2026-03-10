import 'package:dio/dio.dart';

import 'app_exception.dart';

class ErrorMapper {
  const ErrorMapper();

  AppException map(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final message = _extractMessage(error);

      switch (statusCode) {
        case 400:
          return ValidationException(message, statusCode: statusCode, details: _details(error));
        case 401:
          return AuthExpiredException(message, statusCode: statusCode, details: _details(error));
        case 403:
          return UnauthorizedException(message, statusCode: statusCode, details: _details(error));
        case 404:
          return ServerException(message, statusCode: statusCode, details: _details(error));
        case 500:
        case 502:
        case 503:
          return ServerException(message, statusCode: statusCode, details: _details(error));
        default:
          break;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return NetworkException(message, statusCode: statusCode, details: _details(error));
        case DioExceptionType.cancel:
          return UnknownException('Request cancelled', statusCode: statusCode, details: _details(error));
        case DioExceptionType.badResponse:
          return ServerException(message, statusCode: statusCode, details: _details(error));
        case DioExceptionType.badCertificate:
          return ServerException('Invalid SSL certificate', statusCode: statusCode, details: _details(error));
        case DioExceptionType.unknown:
          return UnknownException(message, statusCode: statusCode, details: _details(error));
      }
    }

    return UnknownException(error.toString());
  }

  String _extractMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] ?? responseData['error'];
      if (message is String) {
        return message;
      }
    }

    return error.message ?? 'Unexpected error occurred';
  }

  Map<String, dynamic>? _details(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    return null;
  }
}
