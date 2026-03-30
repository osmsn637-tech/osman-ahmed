import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/network/api_client.dart';

class DeviceManagementRemoteDataSource {
  DeviceManagementRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> registerDevice({
    required String deviceId,
    required String deviceSerial,
    required String model,
    required String osVersion,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppEndpoints.deviceRegister,
      data: <String, dynamic>{
        'device': <String, dynamic>{
          'deviceId': deviceId,
          'deviceSerial': deviceSerial,
          'model': model,
          'osVersion': osVersion,
        },
      },
      parser: _asMap,
    );

    return response.when(
      success: (_) => null,
      failure: (error) => throw error,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}
