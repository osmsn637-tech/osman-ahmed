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
  static const _scanEndDebounceDelay = Duration(milliseconds: 120);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _scanEndDebounce;

  String _value = '';
  String? _error;
  late bool _manualKeyboardEnabled;

  @override
  void initState() {
    super.initState();
    _manualKeyboardEnabled = widget.showKeyboard;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_manualKeyboardEnabled) {
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        _focusForScannerInput();
      }
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

  void _focusForScannerInput() {
    _focusNode.requestFocus();
    // Keep the editable field focused for wedge scanners without opening IME.
    _focusNode.consumeKeyboardToken();
    _hideKeyboardIfNeeded();
  }

  void _enableManualKeyboard() {
    // Manual mode explicitly opts into soft keyboard input.
    if (!mounted) return;
    setState(() {
      _manualKeyboardEnabled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _clearField() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    setState(() {
      _value = '';
      _error = null;
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

    final hasScannerTerminator =
        rawValue.contains('\n') || rawValue.contains('\r');
    final normalized = _normalizeBarcode(rawValue);

    _syncFromText(normalized);

    if (hasScannerTerminator) {
      _searchProduct();
      return;
    }

    if (!_manualKeyboardEnabled) {
      _scheduleAutoSearch();
      return;
    }

    // Slow/manual typing: never auto search.
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
  }

  void _scheduleAutoSearch() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = Timer(_scanEndDebounceDelay, () {
      if (!mounted) return;

      if (!_manualKeyboardEnabled && _value.isNotEmpty) {
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
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle =
        widget.title ?? (widget.isArabic ? '??? ????????' : 'Scan barcode');
    final dialogHint = widget.hintText ??
        (widget.isArabic ? '???? ?? ???? ????????' : 'Scan or enter barcode');
    final manualEntryLabel = widget.isArabic ? '???? ?????' : 'Enter manually';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('scan_barcode_field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: false,
                  showCursor: _manualKeyboardEnabled,
                  readOnly: false,
                  keyboardType: _manualKeyboardEnabled
                      ? TextInputType.number
                      : TextInputType.visiblePassword,
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: dialogHint,
                    errorText: _error,
                    prefixIcon: const Icon(Icons.qr_code_2_rounded),
                    suffixIcon: _manualKeyboardEnabled
                        ? IconButton(
                            key: const Key('lookup_manual_submit_button'),
                            icon: const Icon(Icons.search_rounded),
                            tooltip: 'Search',
                            onPressed: _searchProduct,
                          )
                        : _value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                tooltip: 'Clear',
                                onPressed: _clearField,
                              )
                            : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (_manualKeyboardEnabled) {
                      _focusNode.requestFocus();
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    } else {
                      _focusForScannerInput();
                    }
                  },
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _searchProduct(),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const Key('lookup_manual_entry_button'),
                  onPressed: _enableManualKeyboard,
                  icon: const Icon(Icons.keyboard_alt_rounded),
                  label: Text(manualEntryLabel),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
