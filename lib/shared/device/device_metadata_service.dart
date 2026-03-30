import 'package:flutter/services.dart';

import 'device_metadata.dart';

abstract class DeviceMetadataService {
  Future<DeviceMetadata> loadDeviceMetadata();
}

class PlatformDeviceMetadataService implements DeviceMetadataService {
  const PlatformDeviceMetadataService({
    MethodChannel? methodChannel,
  }) : _methodChannel =
            methodChannel ?? const MethodChannel('com.putaway/scanner');

  final MethodChannel _methodChannel;

  @override
  Future<DeviceMetadata> loadDeviceMetadata() async {
    final payload =
        await _methodChannel.invokeMapMethod<String, dynamic>('getDeviceInfo') ??
            <String, dynamic>{};
    return DeviceMetadata(
      deviceSerial: _readString(payload['deviceSerial']),
      model: _readString(payload['model']),
      osVersion: _readString(payload['osVersion']),
    );
  }

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}
