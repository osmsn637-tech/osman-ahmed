import '../../../../core/utils/result.dart';

abstract class DeviceManagementRepository {
  Future<Result<void>> registerDevice({
    required String deviceId,
    required String deviceSerial,
    required String model,
    required String osVersion,
  });
}
