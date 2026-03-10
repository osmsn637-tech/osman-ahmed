import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({required ErrorMapper errorMapper, required void Function(AppException error) onError})
      : _errorMapper = errorMapper,
        _onError = onError;

  final ErrorMapper _errorMapper;
  final void Function(AppException error) _onError;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _errorMapper.map(err);
    _onError(mapped);
    handler.next(err);
  }
}
