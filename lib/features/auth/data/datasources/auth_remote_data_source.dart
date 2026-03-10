import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../models/login_request_dto.dart';
import '../models/login_response_dto.dart';

abstract class AuthRemoteDataSource {
  Future<Result<LoginResponseDto>> login(LoginRequestDto dto);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Result<LoginResponseDto>> login(LoginRequestDto dto) {
    return _client.post<LoginResponseDto>(
      AppEndpoints.login,
      data: dto.toJson(),
      parser: (data) => LoginResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }
}
