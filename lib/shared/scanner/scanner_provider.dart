import 'dart:async';

import 'package:flutter/foundation.dart';

import 'scanner_interface.dart';
import 'scanner_service.dart';

class ScannerState {
  const ScannerState({
    this.isListening = false,
    this.isEnabled = true,
    this.lastBarcode = '',
    this.errorMessage,
    this.deviceType = ScannerDeviceType.unknown,
  });

  final bool isListening;
  final bool isEnabled;
  final String lastBarcode;
  final String? errorMessage;
  final ScannerDeviceType deviceType;

  ScannerState copyWith({
    bool? isListening,
    bool? isEnabled,
    String? lastBarcode,
    String? errorMessage,
    ScannerDeviceType? deviceType,
  }) {
    return ScannerState(
      isListening: isListening ?? this.isListening,
      isEnabled: isEnabled ?? this.isEnabled,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      errorMessage: errorMessage,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}

class ScannerProvider extends ChangeNotifier {
  ScannerProvider({ScannerInterface? scanner}) : _scanner = scanner ?? ScannerService();

  final ScannerInterface _scanner;
  StreamSubscription<String>? _sub;
  ScannerState _state = const ScannerState();
  ScannerState get state => _state;

  void init() async {
    try {
      if (_state.isListening) return;
      await _scanner.enableScanner();
      await _scanner.startListening();
      _state = _state.copyWith(isListening: true, errorMessage: null);
      _listen();
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  void _listen() {
    _sub?.cancel();
    _sub = _scanner.barcodeStream.listen((barcode) {
      _state = _state.copyWith(lastBarcode: barcode, errorMessage: null);
      notifyListeners();
    }, onError: (err) {
      _state = _state.copyWith(errorMessage: err.toString());
      notifyListeners();
    });
  }

  Future<void> enable() async {
    await _scanner.enableScanner();
    _state = _state.copyWith(isEnabled: true);
    notifyListeners();
  }

  Future<void> disable() async {
    await _scanner.disableScanner();
    _state = _state.copyWith(isEnabled: false);
    notifyListeners();
  }

  Future<void> disposeScanner() async {
    await _scanner.stopListening();
    await _scanner.disableScanner();
    await _sub?.cancel();
    _sub = null;
    _state = _state.copyWith(isListening: false);
  }

  @override
  void dispose() {
    disposeScanner();
    super.dispose();
  }
}
