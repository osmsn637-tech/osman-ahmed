class DeviceMetadata {
  const DeviceMetadata({
    required this.deviceSerial,
    required this.model,
    required this.osVersion,
  });

  final String deviceSerial;
  final String model;
  final String osVersion;
}
