import '../../../../core/utils/result.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_data_source.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl(this._remoteDataSource);

  final AppUpdateRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AppUpdateConfig>> fetchRemoteConfig() {
    return _remoteDataSource.fetchRemoteConfig();
  }
}
