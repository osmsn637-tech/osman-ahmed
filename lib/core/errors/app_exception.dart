import 'package:equatable/equatable.dart';

sealed class AppException extends Equatable implements Exception {
  const AppException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, statusCode, details];

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (status: $statusCode)';
    return '$runtimeType: $message$code';
  }
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode, super.details});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.statusCode, super.details});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.details});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.details}) : super(statusCode: null);
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.statusCode, super.details});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode, super.details});
}

class AuthExpiredException extends AppException {
  const AuthExpiredException(super.message, {super.statusCode, super.details});
}
