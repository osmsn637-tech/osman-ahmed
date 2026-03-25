import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/inbound_entities.dart';
import '../controllers/inbound_receipt_controller.dart';

class InboundReceiptPage extends StatefulWidget {
  const InboundReceiptPage({
    super.key,
    required this.receiptId,
  });

  final String receiptId;

  @override
  State<InboundReceiptPage> createState() => _InboundReceiptPageState();
}

class _InboundReceiptPageState extends State<InboundReceiptPage>
    with WidgetsBindingObserver {
  static const _matchedItemColor = Color(0xFFE7F6EC);
  static const _matchedItemBorderColor = Color(0xFF1F9D55);
  static const _focusRetryDelay = Duration(milliseconds: 250);
  static const _focusRetryCount = 6;
  static const _pageBackground = Color(0xFFF5F7FB);
  static const _panelColor = Colors.white;
  static const _panelBorderColor = Color(0xFFE6EBF2);
  static const _panelTint = Color(0xFFF8FAFD);

  late final TextEditingController _listScanController;
  late final TextEditingController _detailBarcodeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _expirationDateController;
  late final FocusNode _listScanFocusNode;
  late final FocusNode _detailScanFocusNode;
  Timer? _listScanDebounce;
  Timer? _detailScanDebounce;
  Timer? _focusRetryTimer;
  DateTime? _selectedExpirationDate;
  String? _activeDetailItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listScanController = TextEditingController();
    _detailBarcodeController = TextEditingController();
    _quantityController = TextEditingController();
    _expirationDateController = TextEditingController();
    _listScanFocusNode = FocusNode();
    _detailScanFocusNode = FocusNode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listScanDebounce?.cancel();
    _detailScanDebounce?.cancel();
    _focusRetryTimer?.cancel();
    _listScanController.dispose();
    _detailBarcodeController.dispose();
    _quantityController.dispose();
    _expirationDateController.dispose();
    _listScanFocusNode.dispose();
    _detailScanFocusNode.dispose();
    super.dispose();
  }

  void _focusHiddenScanner(FocusNode focusNode) {
    focusNode.requestFocus();
    focusNode.consumeKeyboardToken();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _ensureScannerFocus(FocusNode focusNode) {
    _focusRetryTimer?.cancel();
    var retriesLeft = focusNode.hasFocus ? 0 : _focusRetryCount;
    _focusHiddenScanner(focusNode);
    _focusRetryTimer = Timer.periodic(_focusRetryDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (focusNode.hasFocus || retriesLeft <= 0) {
        timer.cancel();
        return;
      }
      retriesLeft -= 1;
      _focusHiddenScanner(focusNode);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<InboundReceiptController>();
      final selectedItem = controller.selectedItem;
      if (selectedItem == null && controller.canReceiveItems) {
        _ensureScannerFocus(_listScanFocusNode);
        return;
      }
      if (selectedItem != null && !controller.detailOpenedByScan) {
        _ensureScannerFocus(_detailScanFocusNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InboundReceiptController>();
    final receipt = controller.receipt;
    final selectedItem = controller.selectedItem;

    if (_activeDetailItemId != selectedItem?.id) {
      _activeDetailItemId = selectedItem?.id;
      if (selectedItem == null) {
        _setExpirationDate(context, null);
      } else {
        _detailBarcodeController.clear();
        _quantityController.clear();
        _setExpirationDate(context, selectedItem.expirationDate);
      }
    }

    if (selectedItem == null &&
        controller.canReceiveItems &&
        !_listScanFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.selectedItem != null) return;
        _ensureScannerFocus(_listScanFocusNode);
      });
    }

    if (selectedItem != null &&
        !controller.detailOpenedByScan &&
        !_detailScanFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.selectedItem == null) return;
        _ensureScannerFocus(_detailScanFocusNode);
      });
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: selectedItem == null && receipt != null
          ? _buildListBottomBar(context, controller)
          : null,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (controller.isLoading && receipt == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage != null && receipt == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ValidationMessage(
                    message: controller.errorMessage!,
                    isPositive: false,
                  ),
                ),
              );
            }
            if (receipt == null) {
              return const SizedBox.shrink();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selectedItem == null
                  ? _buildListPage(context, controller, receipt)
                  : _buildDetailPage(
                      context,
                      controller,
                      receipt,
                      selectedItem,
                    ),
            );
          },
        ),
      ),
    );
  }

  String _tr(BuildContext context, String english, String arabic) {
    return context.isArabicLocale ? arabic : english;
  }

  String _quantityLabel(
    BuildContext context,
    InboundReceiptController controller,
    InboundReceiptItem item,
  ) {
    if (item.receivedQuantity > 0) {
      return _tr(
        context,
        '${item.receivedQuantity} received',
        '${item.receivedQuantity} تم استلامها',
      );
    }
    return _tr(
      context,
      controller.quantityLabel(item),
      'الكمية المتوقعة: ${item.expectedQuantity}',
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('yyyy-MM-dd', locale).format(date);
  }

  void _setExpirationDate(BuildContext context, DateTime? date) {
    _selectedExpirationDate = date;
    _expirationDateController.text =
        date == null ? '' : _formatDate(context, date);
  }

  Future<void> _pickExpirationDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedExpirationDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      locale: Localizations.localeOf(context),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _setExpirationDate(context, picked);
    });
  }

  Widget _buildListPage(
    BuildContext context,
    InboundReceiptController controller,
    InboundReceipt receipt,
  ) {
    final receivedCount =
        receipt.items.where((item) => item.receivedQuantity > 0).length;
    final totalCount = receipt.items.length;

    return ListView(
      key: const Key('inbound-receipt-list-page'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          _tr(context, 'Receive', 'استلام'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            context,
            'Scan and confirm inbound items with less friction.',
            'امسح عناصر الاستلام وأكدها بشكل أوضح وأسهل.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InfoRow(
                label: 'PO',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 8),
              Text(
                receipt.poNumber,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildHiddenScanField(
          key: const Key('inbound-receipt-hidden-scan-field'),
          controller: _listScanController,
          focusNode: _listScanFocusNode,
          enabled: controller.canReceiveItems,
          onChanged: (value) {
            _listScanDebounce?.cancel();
            _listScanDebounce = Timer(
              const Duration(milliseconds: 150),
              () async {
                final normalized = value.trim();
                _listScanController.clear();
                await controller.scanReceiptItem(normalized);
              },
            );
          },
        ),
        _SectionCard(
          child: _ScanCaptureSummary(
            icon: Icons.qr_code_scanner_rounded,
            emptyText: _tr(context, 'Scan item barcode', 'امسح باركود الصنف'),
            currentValue: _listScanController.text,
            enabled: controller.canReceiveItems,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _tr(context, 'Received Items', 'العناصر المستلمة'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
            _ProgressPill(
              label: _tr(
                context,
                '$receivedCount of $totalCount received',
                '$receivedCount من $totalCount تم استلامها',
              ),
            ),
          ],
        ),
        if (controller.scanErrorMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(
            message: controller.scanErrorMessage!,
            isPositive: false,
          ),
        ],
        const SizedBox(height: 12),
        for (final item in receipt.items) ...[
          _ReceiptItemCard(
            key: Key('inbound-receipt-item-${item.id}'),
            containerKey: Key('inbound-receipt-item-container-${item.id}'),
            imageKey: Key('inbound-receipt-item-image-${item.id}'),
            title: item.itemName,
            barcode: item.barcode,
            imageUrl: item.imageUrl,
            quantityLabel: _quantityLabel(context, controller, item),
            isMatched: controller.isItemMatched(item),
            enabled: controller.canReceiveItems,
            onTap: () {
              _detailBarcodeController.clear();
              _quantityController.clear();
              _setExpirationDate(context, null);
              controller.openItem(item.id, openedByScan: false);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildListBottomBar(
    BuildContext context,
    InboundReceiptController controller,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: _pageBackground,
          border: Border(
            top: BorderSide(color: AppTheme.surfaceAlt),
          ),
        ),
        child: _SectionCard(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('inbound-receipt-start-button'),
              onPressed: controller.canReceiveItems || controller.isStarting
                  ? null
                  : controller.startReceiving,
              child: Text(
                controller.isStarting
                    ? _tr(context, 'Starting...', 'جارٍ البدء...')
                    : _tr(context, 'Start receiving', 'ابدأ الاستلام'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPage(
    BuildContext context,
    InboundReceiptController controller,
    InboundReceipt receipt,
    InboundReceiptItem item,
  ) {
    final quantityEnabled = controller.isQuantityEnabled;

    final title = _tr(context, 'Receive Item', 'استلام صنف');
    final expectedQtyLabel = _tr(context, 'Expected Qty', 'الكمية المتوقعة');
    final scanOrTypeLabel =
        _tr(context, 'Scan or type barcode', 'امسح أو اكتب الباركود');
    final receivedQuantityLabel =
        _tr(context, 'Received quantity', 'الكمية المستلمة');
    final expirationDateLabel =
        _tr(context, 'Expiration date', 'تاريخ الانتهاء');
    final confirmQuantityLabel =
        _tr(context, 'Confirm quantity', 'تأكيد الكمية');
    final quantityValue = int.tryParse(_quantityController.text);
    final canConfirm = quantityEnabled &&
        !controller.isSubmitting &&
        quantityValue != null &&
        quantityValue > 0 &&
        _selectedExpirationDate != null;

    return ListView(
      key: const Key('inbound-receipt-detail-page'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                _detailBarcodeController.clear();
                _quantityController.clear();
                _setExpirationDate(context, null);
                controller.closeDetail();
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InfoRow(
                label: 'PO',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 8),
              Text(
                receipt.poNumber,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReceiptItemThumbnail(
                imageKey: const Key('inbound-receipt-detail-item-image'),
                imageUrl: item.imageUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    if (item.barcode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.barcode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expectedQtyLabel,
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _panelTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _panelBorderColor),
                          ),
                          child: Text(
                            item.expectedQuantity.toString(),
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!controller.detailOpenedByScan) ...[
          _buildHiddenScanField(
            key: const Key('inbound-receipt-detail-barcode-field'),
            controller: _detailBarcodeController,
            focusNode: _detailScanFocusNode,
            enabled: true,
            onChanged: (value) {
              _detailScanDebounce?.cancel();
              _detailScanDebounce = Timer(
                const Duration(milliseconds: 150),
                () => controller.validateSelectedItemBarcode(value),
              );
            },
          ),
          _SectionCard(
            child: _ScanCaptureSummary(
              icon: Icons.qr_code_scanner_rounded,
              emptyText: scanOrTypeLabel,
              currentValue: _detailBarcodeController.text,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          child: Column(
            children: [
              TextField(
                key: const Key('inbound-receipt-detail-quantity-field'),
                controller: _quantityController,
                enabled: quantityEnabled,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Received quantity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  filled: true,
                  fillColor: Colors.white,
                ).copyWith(labelText: receivedQuantityLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('inbound-receipt-detail-expiration-field'),
                controller: _expirationDateController,
                readOnly: true,
                enabled: quantityEnabled,
                onTap: () {
                  if (!quantityEnabled) return;
                  _pickExpirationDate(context);
                },
                decoration: InputDecoration(
                  labelText: expirationDateLabel,
                  prefixIcon: const Icon(Icons.event_outlined),
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('inbound-receipt-detail-confirm-button'),
                  onPressed: !canConfirm
                      ? null
                      : () async {
                          final succeeded =
                              await controller.confirmSelectedItemQuantity(
                            quantityValue,
                            expirationDate: _selectedExpirationDate!,
                          );
                          if (!mounted || !succeeded) return;
                          _detailBarcodeController.clear();
                          _quantityController.clear();
                          setState(() {
                            _setExpirationDate(context, null);
                          });
                        },
                  child: controller.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(confirmQuantityLabel),
                ),
              ),
            ],
          ),
        ),
        if (controller.scanErrorMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(
            message: controller.scanErrorMessage!,
            isPositive: false,
          ),
        ],
      ],
    );
  }

  Widget _buildHiddenScanField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 1,
      height: 1,
      child: TextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: true,
        keyboardType: TextInputType.none,
        onChanged: onChanged,
        decoration: const InputDecoration(
          labelText: 'Hidden scanner field',
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _InboundReceiptPageState._panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _InboundReceiptPageState._panelBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _InboundReceiptPageState._panelTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _InboundReceiptPageState._panelBorderColor),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
            ),
      ),
    );
  }
}

class _ScanCaptureSummary extends StatelessWidget {
  const _ScanCaptureSummary({
    required this.icon,
    required this.emptyText,
    required this.currentValue,
    this.enabled = true,
  });

  final IconData icon;
  final String emptyText;
  final String currentValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isEmpty = currentValue.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: enabled
            ? _InboundReceiptPageState._panelTint
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _InboundReceiptPageState._panelBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: enabled ? AppTheme.primary : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled
                      ? (context.isArabicLocale
                          ? 'حالة الماسح'
                          : 'Scanner status')
                      : (context.isArabicLocale ? 'الماسح متوقف' : 'Scanner off'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmpty ? emptyText : currentValue.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w800,
                        color: enabled
                            ? (isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary)
                            : AppTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({
    required this.message,
    required this.isPositive,
  });

  final String message;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isPositive ? const Color(0xFFE7F6EC) : const Color(0xFFFDECEC);
    final borderColor = isPositive ? AppTheme.success : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            isPositive
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: borderColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemCard extends StatelessWidget {
  const _ReceiptItemCard({
    super.key,
    required this.containerKey,
    required this.imageKey,
    required this.title,
    required this.barcode,
    required this.imageUrl,
    required this.quantityLabel,
    required this.isMatched,
    required this.enabled,
    required this.onTap,
  });

  final Key containerKey;
  final Key imageKey;
  final String title;
  final String barcode;
  final String? imageUrl;
  final String quantityLabel;
  final bool isMatched;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = isMatched
        ? _InboundReceiptPageState._matchedItemBorderColor
        : AppTheme.textMuted;
    final borderColor = isMatched
        ? _InboundReceiptPageState._matchedItemBorderColor
        : AppTheme.surfaceAlt;
    final backgroundColor =
        isMatched ? _InboundReceiptPageState._matchedItemColor : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          key: containerKey,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReceiptItemThumbnail(
                imageKey: imageKey,
                imageUrl: imageUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    if (barcode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        barcode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isMatched
                            ? const Color(0xFFDDF3E6)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMatched
                            ? Icons.check_circle_rounded
                            : Icons.pending_outlined,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quantityLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptItemThumbnail extends StatelessWidget {
  const _ReceiptItemThumbnail({
    required this.imageKey,
    required this.imageUrl,
  });

  final Key imageKey;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      key: imageKey,
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF5D6B82),
      ),
    );

    final trimmed = imageUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        trimmed,
        key: imageKey,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
