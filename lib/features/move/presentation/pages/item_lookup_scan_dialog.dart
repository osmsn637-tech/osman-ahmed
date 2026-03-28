import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wherehouse/shared/l10n/l10n.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';
import 'package:wherehouse/shared/utils/location_codes.dart';

enum LookupScanMode { itemOnly, autoDetect }

enum LookupScanKind { item, location }

class LookupScanResult {
  const LookupScanResult({
    required this.kind,
    required this.value,
  });

  final LookupScanKind kind;
  final String value;
}

Future<LookupScanResult?> showLookupScanDialog(
  BuildContext context, {
  String? title,
  String? hintText,
  String? emptyErrorMessage,
  String? cancelLabel,
  String? continueLabel,
  bool showKeyboard = true,
  LookupScanMode mode = LookupScanMode.autoDetect,
}) {
  return showDialog<LookupScanResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ScanBarcodeDialog(
      title: title,
      hintText: hintText,
      emptyErrorMessage: emptyErrorMessage,
      cancelLabel: cancelLabel,
      continueLabel: continueLabel,
      showKeyboard: showKeyboard,
      mode: mode,
    ),
  );
}

Future<String?> showItemLookupScanDialog(
  BuildContext context, {
  String? title,
  String? hintText,
  String? emptyErrorMessage,
  String? cancelLabel,
  String? continueLabel,
  bool showKeyboard = true,
}) async {
  final result = await showLookupScanDialog(
    context,
    title: title,
    hintText: hintText,
    emptyErrorMessage: emptyErrorMessage,
    cancelLabel: cancelLabel,
    continueLabel: continueLabel,
    showKeyboard: showKeyboard,
    mode: LookupScanMode.itemOnly,
  );
  return result?.value;
}

class _ScanBarcodeDialog extends StatefulWidget {
  const _ScanBarcodeDialog({
    this.title,
    this.hintText,
    this.emptyErrorMessage,
    this.cancelLabel,
    this.continueLabel,
    this.showKeyboard = true,
    this.mode = LookupScanMode.itemOnly,
  });

  final String? title;
  final String? hintText;
  final String? emptyErrorMessage;
  final String? cancelLabel;
  final String? continueLabel;
  final bool showKeyboard;
  final LookupScanMode mode;

  @override
  State<_ScanBarcodeDialog> createState() => _ScanBarcodeDialogState();
}

class _ScanBarcodeDialogState extends State<_ScanBarcodeDialog>
    with WidgetsBindingObserver {
  static const _scanEndDebounceDelay = Duration(milliseconds: 120);
  static const _focusRefreshInterval = Duration(seconds: 1);

  final GlobalKey<EditableTextState> _scannerEditableTextKey =
      GlobalKey<EditableTextState>();
  late FocusNode _focusNode;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocusNode =
      FocusNode(debugLabel: 'lookup-manual-field');
  Timer? _scanEndDebounce;
  Timer? _focusRefreshTimer;
  Timer? _initialScannerRecoveryTimer;

  String _value = '';
  String? _error;
  bool _manualKeypadOpen = false;
  int _scannerFieldEpoch = 0;
  bool _scannerFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = _buildFocusNode();
    WidgetsBinding.instance.addObserver(this);
    _focusRefreshTimer =
        Timer.periodic(_focusRefreshInterval, (_) => _refreshScannerFocus());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusForScannerInput(primeInputMethod: true);
      _scheduleInitialScannerRecovery();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _manualFocusNode.dispose();
    _controller.dispose();
    _manualController.dispose();
    _scanEndDebounce?.cancel();
    _focusRefreshTimer?.cancel();
    _initialScannerRecoveryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    if (_manualKeypadOpen) {
      _manualFocusNode.requestFocus();
      return;
    }
    _resetScannerAttachment(primeInputMethod: true);
  }

  void _hideKeyboardIfNeeded() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _scheduleInitialScannerRecovery() {
    _initialScannerRecoveryTimer?.cancel();
    _initialScannerRecoveryTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        if (!mounted || _manualKeypadOpen || _value.isNotEmpty) {
          return;
        }
        _resetScannerAttachment(primeInputMethod: true);
      },
    );
  }

  void _focusForScannerInput({bool primeInputMethod = false}) {
    FocusScope.of(context).requestFocus(_focusNode);
    _focusNode.requestFocus();
    _focusNode.consumeKeyboardToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualKeypadOpen) return;
      _scannerEditableTextKey.currentState?.requestKeyboard();
      if (primeInputMethod) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
      _hideKeyboardIfNeeded();
    });
  }

  FocusNode _buildFocusNode() {
    final node = FocusNode(debugLabel: 'lookup-scan-field');
    node.addListener(_handleScannerFocusChanged);
    return node;
  }

  void _handleScannerFocusChanged() {
    if (!mounted) return;
    final hasFocus = _focusNode.hasFocus;
    if (_scannerFocused == hasFocus) return;
    setState(() {
      _scannerFocused = hasFocus;
    });
  }

  void _resetScannerAttachment({bool primeInputMethod = false}) {
    if (!mounted) return;

    final previousFocusNode = _focusNode;
    previousFocusNode.removeListener(_handleScannerFocusChanged);
    final nextFocusNode = _buildFocusNode();

    setState(() {
      _focusNode = nextFocusNode;
      _scannerFieldEpoch += 1;
      _scannerFocused = nextFocusNode.hasFocus;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousFocusNode.dispose();
      if (!mounted || _manualKeypadOpen) return;
      _focusForScannerInput(primeInputMethod: primeInputMethod);
    });
  }

  void _refreshScannerFocus() {
    if (!mounted || _manualKeypadOpen) return;
    if (_focusNode.context == null || !_focusNode.hasFocus) {
      _resetScannerAttachment(primeInputMethod: true);
      return;
    }
    _focusForScannerInput();
  }

  void _handlePopupPointerDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_manualKeypadOpen) {
        _manualFocusNode.requestFocus();
        return;
      }
      _resetScannerAttachment(primeInputMethod: true);
    });
  }

  void _openManualKeypad() {
    if (!mounted) return;
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    _initialScannerRecoveryTimer?.cancel();
    setState(() {
      _manualKeypadOpen = true;
      _value = '';
      _error = null;
      _controller.clear();
      _manualController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_manualKeypadOpen) return;
      _manualFocusNode.requestFocus();
    });
  }

  void _closeManualKeypad() {
    if (!mounted) return;
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    _initialScannerRecoveryTimer?.cancel();
    setState(() {
      _manualKeypadOpen = false;
      _value = '';
      _error = null;
      _manualController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualKeypadOpen) return;
      _resetScannerAttachment(primeInputMethod: true);
    });
  }

  void _clearField() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;
    setState(() {
      _value = '';
      _error = null;
      _controller.clear();
      _manualController.clear();
    });
  }

  void _syncFromText(String value) {
    final normalized = _normalizeScanValue(value);
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
    if (_normalizeScanValue(rawValue).isNotEmpty) {
      _initialScannerRecoveryTimer?.cancel();
    }
    if (_error != null) {
      setState(() => _error = null);
    }

    final hasScannerTerminator =
        rawValue.contains('\n') || rawValue.contains('\r');
    final normalized = _normalizeScanValue(rawValue);

    _syncFromText(normalized);

    if (hasScannerTerminator) {
      _submitScan();
      return;
    }

    _scheduleAutoSearch();
  }

  void _onManualTextChanged(String rawValue) {
    final normalized = _normalizeScanValue(rawValue);
    if (normalized.isNotEmpty) {
      _initialScannerRecoveryTimer?.cancel();
    }
    if (_error != null) {
      setState(() => _error = null);
    }
    if (normalized == _value && normalized == _manualController.text) return;

    setState(() {
      _value = normalized;
      _manualController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    });
  }

  void _scheduleAutoSearch() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = Timer(_scanEndDebounceDelay, () {
      if (!mounted) return;

      if (_value.isNotEmpty) {
        _submitScan();
      }
    });
  }

  void _submitScan() {
    _scanEndDebounce?.cancel();
    _scanEndDebounce = null;

    final value = _normalizeScanValue(_value);
    if (value.isEmpty) {
      setState(
        () => _error = widget.emptyErrorMessage ??
            context.trText(
              english: widget.mode == LookupScanMode.autoDetect
                  ? 'Enter a valid barcode or location'
                  : 'Enter a valid barcode',
              arabic: widget.mode == LookupScanMode.autoDetect
                  ? 'أدخل باركودًا أو موقعًا صالحًا'
                  : 'أدخل باركودًا صالحًا',
              urdu: widget.mode == LookupScanMode.autoDetect
                  ? 'درست بارکوڈ یا مقام درج کریں'
                  : 'درست بارکوڈ درج کریں',
            ),
      );
      return;
    }

    _clearField();
    Navigator.of(context).pop(_buildResult(value));
  }

  LookupScanResult _buildResult(String value) {
    final normalized = _normalizeScanValue(value);
    if (widget.mode == LookupScanMode.autoDetect &&
        isRecognizedLocationCode(normalized)) {
      return LookupScanResult(
        kind: LookupScanKind.location,
        value: normalized,
      );
    }
    return LookupScanResult(
      kind: LookupScanKind.item,
      value: normalized,
    );
  }

  String _normalizeScanValue(String value) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.title ??
        context.trText(
          english: widget.mode == LookupScanMode.autoDetect
              ? 'Scan barcode or location'
              : 'Scan barcode',
          arabic: widget.mode == LookupScanMode.autoDetect
              ? 'امسح الباركود أو الموقع'
              : 'امسح الباركود',
          urdu: widget.mode == LookupScanMode.autoDetect
              ? 'بارکوڈ یا مقام اسکین کریں'
              : 'بارکوڈ اسکین کریں',
        );
    final dialogHint = widget.hintText ??
        context.trText(
          english: widget.mode == LookupScanMode.autoDetect
              ? 'Scan an item barcode or location code'
              : 'Scanner stays ready',
          arabic: widget.mode == LookupScanMode.autoDetect
              ? 'امسح باركود الصنف أو كود الموقع'
              : 'الماسح يبقى جاهزًا',
          urdu: widget.mode == LookupScanMode.autoDetect
              ? 'آئٹم بارکوڈ یا مقام کوڈ اسکین کریں'
              : 'اسکینر تیار رہے گا',
        );
    final manualEntryLabel = context.trText(
      english: 'Manual Type',
      arabic: 'إدخال يدوي',
      urdu: 'دستی اندراج',
    );
    final confirmLabel = context.trText(
      english: 'Confirm',
      arabic: 'تأكيد',
      urdu: 'تصدیق کریں',
    );
    final cancelManualLabel = context.trText(
      english: 'Cancel',
      arabic: 'إلغاء',
      urdu: 'منسوخ کریں',
    );
    final scannerReadyLabel = context.trText(
      english: 'Scanner focus active',
      arabic: 'تركيز الماسح نشط',
      urdu: 'اسکینر فوکس فعال ہے',
    );
    final scannerLostLabel = context.trText(
      english: 'Scanner lost focus',
      arabic: 'الماسح غير متصل',
      urdu: 'اسکینر کا فوکس ختم ہو گیا',
    );
    final statusLabel = _scannerFocused ? scannerReadyLabel : scannerLostLabel;
    final statusValue = _value.isEmpty
        ? context.trText(
            english: widget.mode == LookupScanMode.autoDetect
                ? 'Waiting for barcode or location scan'
                : 'Waiting for barcode scan',
            arabic: widget.mode == LookupScanMode.autoDetect
                ? 'بانتظار مسح الباركود أو الموقع'
                : 'بانتظار مسح الباركود',
            urdu: widget.mode == LookupScanMode.autoDetect
                ? 'بارکوڈ یا مقام اسکین کا انتظار ہے'
                : 'بارکوڈ اسکین کا انتظار ہے',
          )
        : _value;
    final statusHint = _scannerFocused
        ? dialogHint
        : context.trText(
            english: 'Tap the popup to reconnect the scanner',
            arabic: 'اضغط على النافذة لإعادة تفعيل الماسح',
            urdu: 'اسکینر دوبارہ جوڑنے کے لیے پاپ اپ پر ٹیپ کریں',
          );
    final theme = Theme.of(context);
    const cardColor = AppTheme.primary;
    const insetColor = Color(0xFF184E77);
    const secondaryButtonColor = Color(0xFF2A5F8F);
    const panelAccentColor = Color(0xFF3A78A8);
    const contentColor = Colors.white;
    const mutedContentColor = Color(0xFFD9E8F5);
    const readyColor = Color(0xFFB8F7C8);
    const lostColor = Color(0xFFFFD2A8);

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
                        key: Key('scan_barcode_field_$_scannerFieldEpoch'),
                        width: 1,
                        height: 1,
                        child: KeyedSubtree(
                          key: const Key('scan_barcode_field'),
                          child: EditableText(
                            key: _scannerEditableTextKey,
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
                            onSubmitted: (_) => _submitScan(),
                          ),
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
                          tooltip: context.trText(
                            english: 'Close',
                            arabic: 'إغلاق',
                            urdu: 'بند کریں',
                          ),
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
                                      key: const Key(
                                          'lookup_scanner_status_label'),
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: _scannerFocused
                                            ? readyColor
                                            : lostColor,
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
                                      statusHint,
                                      key: const Key(
                                          'lookup_scanner_status_hint'),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                                  tooltip: context.trText(
                                    english: 'Clear',
                                    arabic: 'مسح',
                                    urdu: 'صاف کریں',
                                  ),
                                  color: mutedContentColor,
                                  onPressed: _clearField,
                                )
                              else
                                IconButton(
                                  key: const Key('lookup_reconnect_button'),
                                  onPressed: () => _resetScannerAttachment(
                                    primeInputMethod: true,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  tooltip: context.trText(
                                    english: 'Reconnect scanner',
                                    arabic: 'إعادة تفعيل الماسح',
                                    urdu: 'اسکینر دوبارہ جوڑیں',
                                  ),
                                  color:
                                      _scannerFocused ? readyColor : lostColor,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 36,
                                    height: 36,
                                  ),
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
                        key: const Key('lookup_manual_entry_card'),
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
                              context.trText(
                                english: widget.mode == LookupScanMode.autoDetect
                                    ? 'Type barcode or location manually'
                                    : 'Type barcode manually',
                                arabic: widget.mode == LookupScanMode.autoDetect
                                    ? 'أدخل الباركود أو الموقع يدويًا'
                                    : 'أدخل الباركود يدويًا',
                                urdu: widget.mode == LookupScanMode.autoDetect
                                    ? 'بارکوڈ یا مقام دستی طور پر درج کریں'
                                    : 'بارکوڈ دستی طور پر درج کریں',
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const Key('lookup_manual_text_field'),
                              controller: _manualController,
                              focusNode: _manualFocusNode,
                              keyboardType:
                                  widget.mode == LookupScanMode.autoDetect
                                      ? TextInputType.text
                                      : TextInputType.number,
                              textInputAction: TextInputAction.done,
                              autofocus: true,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                hintText: context.trText(
                                  english:
                                      widget.mode == LookupScanMode.autoDetect
                                          ? 'Enter barcode or location code'
                                          : 'Enter barcode digits',
                                  arabic:
                                      widget.mode == LookupScanMode.autoDetect
                                          ? 'أدخل الباركود أو كود الموقع'
                                          : 'أدخل أرقام الباركود',
                                  urdu:
                                      widget.mode == LookupScanMode.autoDetect
                                          ? 'بارکوڈ یا مقام کوڈ درج کریں'
                                          : 'بارکوڈ کے ہندسے درج کریں',
                                ),
                                hintStyle: theme.textTheme.titleSmall?.copyWith(
                                  color: mutedContentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      const BorderSide(color: panelAccentColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:
                                      const BorderSide(color: panelAccentColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: readyColor,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              inputFormatters: widget.mode ==
                                      LookupScanMode.autoDetect
                                  ? const <TextInputFormatter>[]
                                  : <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                              onChanged: _onManualTextChanged,
                              onSubmitted: (_) {
                                if (_value.isNotEmpty) {
                                  _submitScan();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _LookupActionButton(
                                    key: const Key(
                                        'lookup_manual_cancel_button'),
                                    label: cancelManualLabel,
                                    onPressed: _closeManualKeypad,
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _LookupActionButton(
                                    key: const Key(
                                        'lookup_manual_confirm_button'),
                                    label: confirmLabel,
                                    onPressed:
                                        _value.isEmpty ? null : _submitScan,
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
