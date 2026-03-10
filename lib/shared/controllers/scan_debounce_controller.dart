import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class ScanDebounceController extends ChangeNotifier {
  String? _lastScan;
  Timer? _debounce;

  void handleScanCode({
    required String code,
    required bool hasLoadedItem,
    required Future<void> Function(String code) onFirstScan,
    required void Function(String code) onNextScan,
  }) {
    if (code.isEmpty || _lastScan == code) {
      return;
    }
    _lastScan = code;
    if (!hasLoadedItem) {
      onFirstScan(code);
      return;
    }
    onNextScan(code);
  }

  void runDebounced({
    Duration delay = const Duration(milliseconds: 100),
    required Future<void> Function() action,
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () async {
      await action();
    });
  }

  @mustCallSuper
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
