import 'dart:async';
import 'package:flutter/services.dart';

import 'scanner_interface.dart';

class ScannerService implements ScannerInterface {
  ScannerService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('com.putaway/scanner'),
        _eventChannel = eventChannel ?? const EventChannel('com.putaway/scanner/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<String>? _stream;

  @override
  Stream<String> get barcodeStream =>
      _stream ??= _eventChannel.receiveBroadcastStream().where((event) => event is String).cast<String>();

  @override
  Future<void> startListening() async {
    await _methodChannel.invokeMethod('startListening');
  }

  @override
  Future<void> stopListening() async {
    await _methodChannel.invokeMethod('stopListening');
  }

  @override
  Future<void> enableScanner() async {
    await _methodChannel.invokeMethod('enableScanner');
  }

  @override
  Future<void> disableScanner() async {
    await _methodChannel.invokeMethod('disableScanner');
  }

  Future<ScannerDeviceType> getDeviceType() async {
    final type = await _methodChannel.invokeMethod<String>('getDeviceType');
    switch (type) {
      case 'zebra':
        return ScannerDeviceType.zebra;
      case 'honeywell':
        return ScannerDeviceType.honeywell;
      default:
        return ScannerDeviceType.unknown;
    }
  }
}
