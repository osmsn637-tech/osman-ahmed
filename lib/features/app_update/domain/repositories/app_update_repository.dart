import '../../../../core/utils/result.dart';
import '../entities/app_update_config.dart';

abstract class AppUpdateRepository {
  Future<Result<AppUpdateConfig>> fetchRemoteConfig();
}
