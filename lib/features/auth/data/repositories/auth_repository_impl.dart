import '../../../../core/auth/token_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/login_params.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_dto.dart';
import '../models/login_response_dto.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource, required TokenRepository tokenRepository})
      : _remoteDataSource = remoteDataSource,
        _tokenRepository = tokenRepository;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenRepository _tokenRepository;

  @override
  Future<Result<User>> login(LoginParams params) async {
    final response = await _remoteDataSource.login(
      LoginRequestDto(
        phone: params.phone,
        password: params.password,
        countryCode: params.countryCode,
      ),
    );

    return switch (response) {
      Success<LoginResponseDto>(data: final dto) => _persistAndReturnUser(dto),
      Failure<LoginResponseDto>(error: final error) => Failure<User>(error),
    };
  }

  Future<Result<User>> _persistAndReturnUser(LoginResponseDto dto) async {
    await _tokenRepository.saveTokens(
      accessToken: dto.tokens.accessToken,
      refreshToken: dto.tokens.refreshToken,
    );
    await _tokenRepository.saveUser(dto.user.toJson());
    return Success<User>(dto.user);
  }

  @override
  Future<Result<void>> logout() async {
    await _tokenRepository.clear();
    return const Success<void>(null);
  }

  @override
  Future<Result<User?>> loadPersistedSession() async {
    final access = await _tokenRepository.getAccessToken();
    final refresh = await _tokenRepository.getRefreshToken();
    final userJson = await _tokenRepository.readUser();

    if (access == null || refresh == null || userJson == null) {
      return const Success<User?>(null);
    }

    try {
      return Success<User?>(UserModel.fromJson(userJson));
    } catch (e) {
      await _tokenRepository.clear();
      return Failure<User?>(e);
    }
  }
}
