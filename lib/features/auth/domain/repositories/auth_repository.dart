import '../entities/user.dart';
import '../entities/login_params.dart';
import '../../../../core/utils/result.dart';

abstract class AuthRepository {
  Future<Result<User>> login(LoginParams params);
  Future<Result<User?>> loadPersistedSession();
  Future<Result<void>> logout();
}
