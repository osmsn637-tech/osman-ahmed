import '../../../../core/utils/result.dart';
import '../../domain/repositories/device_management_repository.dart';
import '../datasources/device_management_remote_data_source.dart';

class DeviceManagementRepositoryImpl implements DeviceManagementRepository {
  DeviceManagementRepositoryImpl(this._remoteDataSource);

  final DeviceManagementRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> registerDevice({
    required String deviceId,
    required String deviceSerial,
    required String model,
    required String osVersion,
  }) async {
    try {
      await _remoteDataSource.registerDevice(
        deviceId: deviceId,
        deviceSerial: deviceSerial,
        model: model,
        osVersion: osVersion,
      );
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(error);
    }
  }
}
