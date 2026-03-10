import 'package:dio/dio.dart';

import '../errors/error_mapper.dart';
import '../utils/result.dart';

class ApiClient {
  ApiClient(this._dio, this._errorMapper);

  final Dio _dio;
  final ErrorMapper _errorMapper;

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      );
      return Success<T>(_parse(response.data, parser));
    } catch (error) {
      return Failure<T>(_errorMapper.map(error));
    }
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      );
      return Success<T>(_parse(response.data, parser));
    } catch (error) {
      return Failure<T>(_errorMapper.map(error));
    }
  }

  T _parse<T>(dynamic data, T Function(dynamic data)? parser) {
    if (parser != null) {
      return parser(data);
    }
    return data as T;
  }
}
