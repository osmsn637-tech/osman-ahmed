import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';

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

class _ScanBarcodeDialogState extends State<_ScanBarcodeDialog>
    with WidgetsBindingObserver {
  static const _scanEndDebounceDelay = Duration(milliseconds: 120);
  static const _focusRefreshInterval = Duration(seconds: 1);
  static const _manualDigits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  late FocusNode _focusNode;
  final TextEditingController _controller = TextEditingController();
  Timer? _scanEndDebounce;
  Timer? _focusRefreshTimer;

  String _value = '';
  String? _error;
  bool _manualKeypadOpen = false;
  int _scannerFieldEpoch = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'lookup-scan-field');
    WidgetsBinding.instance.addObserver(this);
    _focusRefreshTimer =
        Timer.periodic(_focusRefreshInterval, (_) => _refreshScannerFocus());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusForScannerInput();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    _scanEndDebounce?.cancel();
    _focusRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resetScannerAttachment();
    });
  }

  void _hideKeyboardIfNeeded() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _focusForScannerInput() {
    _focusNode.requestFocus();
    _focusNode.consumeKeyboardToken();
    _hideKeyboardIfNeeded();
  }

  void _resetScannerAttachment() {
    if (!mounted) return;

    final previousFocusNode = _focusNode;
    final nextFocusNode = FocusNode(debugLabel: 'lookup-scan-field');

    setState(() {
      _focusNode = nextFocusNode;
      _scannerFieldEpoch += 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousFocusNode.dispose();
      if (!mounted || _manualKeypadOpen) return;
      _focusForScannerInput();
    });
  }

  void _refreshScannerFocus() {
    if (!mounted || _manualKeypadOpen) return;
    if (_controller.text.isEmpty) {
      _resetScannerAttachment();
      return;
    }
    _focusForScannerInput();
  }

  void _handlePopupPointerDown() {
    if (_manualKeypadOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualKeypadOpen) return;
      _resetScannerAttachment();
    });
  }

  void _openManualKeypad() {
    if (!mounted) return;
    setState(() {
      _manualKeypadOpen = true;
      _value = '';
      _error = null;
      _controller.clear();
    });
    _focusForScannerInput();
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
    if (_error != null) {
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

    _scheduleAutoSearch();
  }

  void _scheduleAutoSearch() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = Timer(_scanEndDebounceDelay, () {
      if (!mounted) return;

      if (_value.isNotEmpty) {
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
            (widget.isArabic
                ? 'أدخل باركودًا صالحًا'
                : 'Enter a valid barcode'),
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

  void _appendManualDigit(String digit) {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    setState(() {
      _error = null;
      _value += digit;
      _controller.value = TextEditingValue(
        text: _value,
        selection: TextSelection.collapsed(offset: _value.length),
      );
    });
  }

  void _deleteManualDigit() {
    if (_value.isEmpty) return;
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    final nextValue = _value.substring(0, _value.length - 1);
    setState(() {
      _error = null;
      _value = nextValue;
      _controller.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle =
        widget.title ?? (widget.isArabic ? 'امسح الباركود' : 'Scan barcode');
    final dialogHint = widget.hintText ??
        (widget.isArabic ? 'الماسح يبقى جاهزًا' : 'Scanner stays ready');
    final manualEntryLabel = widget.isArabic ? 'إدخال يدوي' : 'Manual Type';
    final confirmLabel = widget.isArabic ? 'تأكيد' : 'Confirm';
    final deleteLabel = widget.isArabic ? 'حذف' : 'Delete';
    final statusLabel = widget.isArabic
        ? 'إدخال الماسح جاهز'
        : 'Hidden scanner input is active';
    final statusValue = _value.isEmpty
        ? (widget.isArabic
            ? 'بانتظار مسح الباركود'
            : 'Waiting for barcode scan')
        : _value;
    final theme = Theme.of(context);
    const cardColor = AppTheme.primary;
    const insetColor = Color(0xFF184E77);
    const secondaryButtonColor = Color(0xFF2A5F8F);
    const panelAccentColor = Color(0xFF3A78A8);
    const contentColor = Colors.white;
    const mutedContentColor = Color(0xFFD9E8F5);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _handlePopupPointerDown(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            key: const Key('lookup_dialog_card'),
            decoration: BoxDecoration(
              color: cardColor,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        key: ValueKey<int>(_scannerFieldEpoch),
                        width: 1,
                        height: 1,
                        child: EditableText(
                          key: const Key('scan_barcode_field'),
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          showCursor: false,
                          readOnly: false,
                          keyboardType: TextInputType.none,
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 1,
                            height: 1,
                          ),
                          cursorColor: Colors.transparent,
                          backgroundCursorColor: Colors.transparent,
                          selectionColor: Colors.transparent,
                          onChanged: _onTextChanged,
                          onSubmitted: (_) => _searchProduct(),
                        ),
                      ),
                    ),
                    Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: contentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dialogTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: contentColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: widget.isArabic ? 'إغلاق' : 'Close',
                        color: contentColor,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                    if (!_manualKeypadOpen) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: insetColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: panelAccentColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.center_focus_strong_rounded,
                                color: contentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    statusLabel,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: mutedContentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusValue,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: contentColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dialogHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mutedContentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_value.isNotEmpty)
                              IconButton(
                                key: const Key('lookup_clear_button'),
                                icon: const Icon(Icons.close_rounded),
                                tooltip: widget.isArabic ? 'مسح' : 'Clear',
                                color: mutedContentColor,
                                onPressed: _clearField,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                    if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFFD2D2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                    if (!_manualKeypadOpen) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('lookup_manual_entry_button'),
                        onPressed: _openManualKeypad,
                        icon: const Icon(Icons.keyboard_alt_rounded),
                        label: Text(manualEntryLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: secondaryButtonColor,
                          foregroundColor: contentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                    if (_manualKeypadOpen) ...[
                    const SizedBox(height: 14),
                    Container(
                      key: const Key('lookup_manual_keypad'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: insetColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: panelAccentColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isArabic
                                ? 'أدخل الباركود يدويًا'
                                : 'Type barcode manually',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: contentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: panelAccentColor),
                            ),
                            child: Text(
                              _value.isEmpty
                                  ? (widget.isArabic
                                      ? 'أدخل أرقام الباركود'
                                      : 'Enter barcode digits')
                                  : _value,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Table(
                            key: const Key('lookup_manual_digit_grid'),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              for (var row = 0; row < 3; row++)
                                TableRow(
                                  children: [
                                    for (var column = 0; column < 3; column++)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: column == 2 ? 0 : 8,
                                          bottom: row == 2 ? 0 : 8,
                                        ),
                                        child: _LookupKeypadButton(
                                          key: Key(
                                            'lookup_manual_digit_${_manualDigits[(row * 3) + column]}',
                                          ),
                                          label:
                                              _manualDigits[(row * 3) + column],
                                          onPressed: () => _appendManualDigit(
                                            _manualDigits[(row * 3) + column],
                                          ),
                                          backgroundColor: secondaryButtonColor,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 10,
                                child: _LookupActionButton(
                                  key: const Key('lookup_manual_delete_button'),
                                  label: deleteLabel,
                                  onPressed: _deleteManualDigit,
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 12,
                                child: _LookupActionButton(
                                  key: const Key('lookup_manual_digit_0'),
                                  label: '0',
                                  onPressed: () => _appendManualDigit('0'),
                                  backgroundColor: secondaryButtonColor,
                                  foregroundColor: contentColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 10,
                                child: _LookupActionButton(
                                  key:
                                      const Key('lookup_manual_confirm_button'),
                                  label: confirmLabel,
                                  onPressed:
                                      _value.isEmpty ? null : _searchProduct,
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  emphasized: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LookupKeypadButton extends StatelessWidget {
  const _LookupKeypadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppTheme.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LookupActionButton extends StatelessWidget {
  const _LookupActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(backgroundColor),
        foregroundColor: WidgetStatePropertyAll(foregroundColor),
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: emphasized ? 18 : 16,
            vertical: 14,
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
