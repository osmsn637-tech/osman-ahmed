import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showItemLookupScanDialog(
  BuildContext context, {
  String? title,
  String? hintText,
  String? emptyErrorMessage,
  String? cancelLabel,
  String? continueLabel,
  bool showKeyboard = true,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ScanBarcodeDialog(
      isArabic: isArabic,
      title: title,
      hintText: hintText,
      emptyErrorMessage: emptyErrorMessage,
      cancelLabel: cancelLabel,
      continueLabel: continueLabel,
      showKeyboard: showKeyboard,
    ),
  );
}

class _ScanBarcodeDialog extends StatefulWidget {
  const _ScanBarcodeDialog({
    required this.isArabic,
    this.title,
    this.hintText,
    this.emptyErrorMessage,
    this.cancelLabel,
    this.continueLabel,
    this.showKeyboard = true,
  });

  final bool isArabic;
  final String? title;
  final String? hintText;
  final String? emptyErrorMessage;
  final String? cancelLabel;
  final String? continueLabel;
  final bool showKeyboard;

  @override
  State<_ScanBarcodeDialog> createState() => _ScanBarcodeDialogState();
}

class _ScanBarcodeDialogState extends State<_ScanBarcodeDialog> {
  static const _scannerKeystrokeWindow = Duration(milliseconds: 50);
  static const _scanEndDebounceDelay = Duration(milliseconds: 120);
  static const _scannerMinLength = 4;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _scanEndDebounce;

  DateTime? _lastKeystroke;
  String _value = '';
  String? _error;
  int _consecutiveFastKeystrokes = 0;
  bool _isLikelyScanner = false;
  bool _manualKeyboardEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Keep focus on the field so hardware scanners can type even when keyboard is hidden.
      _focusNode.requestFocus();
      _hideKeyboardIfNeeded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scanEndDebounce?.cancel();
    super.dispose();
  }

  void _hideKeyboardIfNeeded() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _enableManualKeyboard() {
    // User explicitly tapped the field. Open soft keyboard and treat incoming input as manual.
    _manualKeyboardEnabled = true;
    if (!mounted) return;
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  void _clearField() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    setState(() {
      _value = '';
      _error = null;
      _consecutiveFastKeystrokes = 0;
      _isLikelyScanner = false;
      _lastKeystroke = null;
      _controller.clear();
    });
  }

  void _syncFromText(String value) {
    final normalized = _normalizeBarcode(value);
    if (normalized == _value) return;
    setState(() {
      _value = normalized;
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    });
  }

  void _onTextChanged(String rawValue) {
    if (_manualKeyboardEnabled && _error != null) {
      setState(() => _error = null);
    }

    final hasScannerTerminator = rawValue.contains('\n') || rawValue.contains('\r');
    final normalized = _normalizeBarcode(rawValue);

    _trackTypingSpeed(normalized);
    _syncFromText(normalized);

    if (hasScannerTerminator) {
      _searchProduct();
      return;
    }

    if (_isLikelyScanner && !_manualKeyboardEnabled) {
      _scheduleAutoSearch();
      return;
    }

    // Slow/manual typing: never auto search.
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
  }

  void _trackTypingSpeed(String normalizedValue) {
    final previous = _value;
    if (normalizedValue.length <= previous.length) {
      // Backspace/replace/clear resets scanner detection state.
      _consecutiveFastKeystrokes = 0;
      _isLikelyScanner = false;
      _lastKeystroke = null;
      return;
    }

    final now = DateTime.now();
    final addedChars = normalizedValue.length - previous.length;
    final wasFast = _lastKeystroke != null &&
        now.difference(_lastKeystroke!) <= _scannerKeystrokeWindow;
    _lastKeystroke = now;

    if (_manualKeyboardEnabled) {
      _isLikelyScanner = false;
      _consecutiveFastKeystrokes = 0;
      return;
    }

    _consecutiveFastKeystrokes =
        wasFast ? (_consecutiveFastKeystrokes + addedChars) : addedChars;
    _isLikelyScanner =
        _consecutiveFastKeystrokes >= _scannerMinLength &&
        normalizedValue.length >= _scannerMinLength;

    // If typing slows down, stop treating as a scanner burst.
    if (!wasFast) {
      _isLikelyScanner = false;
    }
  }

  void _scheduleAutoSearch() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = Timer(_scanEndDebounceDelay, () {
      if (!mounted) return;

      if (_isLikelyScanner && !_manualKeyboardEnabled && _value.length >= _scannerMinLength) {
        _searchProduct();
      }
    });
  }

  void _searchProduct() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;

    final barcode = _normalizeBarcode(_value);
    if (barcode.isEmpty) {
      setState(
        () => _error = widget.emptyErrorMessage ??
            (widget.isArabic ? '???? ?????? ????' : 'Enter a valid barcode'),
      );
      return;
    }

    // Clear immediately after successful detection and return the value.
    // This keeps the field reset while still closing the dialog for the caller.
    _clearField();
    Navigator.of(context).pop(barcode);
  }

  String _normalizeBarcode(String value) {
    return value
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle =
        widget.title ?? (widget.isArabic ? '??? ????????' : 'Scan barcode');
    final dialogHint =
        widget.hintText ?? (widget.isArabic ? '???? ?? ???? ????????' : 'Scan or enter barcode');
    final dialogContinueLabel =
        widget.continueLabel ?? (widget.isArabic ? '??????' : 'Continue');

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(dialogTitle)),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('scan_barcode_field'),
            controller: _controller,
            focusNode: _focusNode,
            autofocus: false,
            showCursor: true,
            readOnly: false,
            keyboardType:
                _manualKeyboardEnabled ? TextInputType.text : TextInputType.none,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: dialogHint,
              prefixIcon: const Icon(Icons.qr_code_scanner),
              errorText: _error,
              suffixIcon: _value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: _clearField,
                    )
                  : null,
            ),
            onTap: () {
              _enableManualKeyboard();
            },
            onChanged: _onTextChanged,
            onSubmitted: (_) => _searchProduct(),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _searchProduct,
          child: Text(dialogContinueLabel),
        ),
      ],
    );
  }
}
