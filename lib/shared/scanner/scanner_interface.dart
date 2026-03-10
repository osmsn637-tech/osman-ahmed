enum ScannerDeviceType { zebra, honeywell, unknown }

abstract class ScannerInterface {
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> enableScanner();
  Future<void> disableScanner();
  Stream<String> get barcodeStream;
}

typedef ScannerFactory = Future<ScannerInterface> Function(ScannerDeviceType type);
