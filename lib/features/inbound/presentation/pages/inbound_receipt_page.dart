import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

class _InboundReceiptPageState extends State<InboundReceiptPage> {
  static const _matchedItemColor = Color(0xFFE7F6EC);
  static const _matchedItemBorderColor = Color(0xFF1F9D55);

  late final TextEditingController _listScanController;
  late final TextEditingController _detailBarcodeController;
  late final TextEditingController _quantityController;
  late final FocusNode _listScanFocusNode;
  Timer? _listScanDebounce;
  Timer? _detailScanDebounce;

  @override
  void initState() {
    super.initState();
    _listScanController = TextEditingController();
    _detailBarcodeController = TextEditingController();
    _quantityController = TextEditingController();
    _listScanFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _listScanDebounce?.cancel();
    _detailScanDebounce?.cancel();
    _listScanController.dispose();
    _detailBarcodeController.dispose();
    _quantityController.dispose();
    _listScanFocusNode.dispose();
    super.dispose();
  }

  void _focusHiddenScanner(FocusNode focusNode) {
    focusNode.requestFocus();
    focusNode.consumeKeyboardToken();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InboundReceiptController>();
    final receipt = controller.receipt;
    final selectedItem = controller.selectedItem;

    if (selectedItem == null &&
        controller.canReceiveItems &&
        !_listScanFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusHiddenScanner(_listScanFocusNode);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem == null ? 'Receive' : 'Receive Item'),
        leading: selectedItem == null
            ? null
            : IconButton(
                onPressed: () {
                  _detailBarcodeController.clear();
                  _quantityController.clear();
                  controller.closeDetail();
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
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
              return Center(child: Text(controller.errorMessage!));
            }
            if (receipt == null) {
              return const SizedBox.shrink();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selectedItem == null
                  ? _buildListPage(context, controller, receipt)
                  : _buildDetailPage(
                      context, controller, receipt, selectedItem),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListPage(
    BuildContext context,
    InboundReceiptController controller,
    InboundReceipt receipt,
  ) {
    return ListView(
      key: const Key('inbound-receipt-list-page'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ReceiptInfoCard(
          label: 'PO',
          value: receipt.poNumber,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('inbound-receipt-hidden-scan-field'),
          controller: _listScanController,
          focusNode: _listScanFocusNode,
          enabled: controller.canReceiveItems,
          autofocus: true,
          keyboardType: TextInputType.none,
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
          decoration: const InputDecoration(
            labelText: 'Scan item barcode',
          ),
        ),
        const SizedBox(height: 12),
        if (controller.scanErrorMessage != null) ...[
          Text(
            controller.scanErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
        ],
        for (final item in receipt.items) ...[
          _ReceiptItemCard(
            key: Key('inbound-receipt-item-${item.id}'),
            containerKey: Key('inbound-receipt-item-container-${item.id}'),
            imageKey: Key('inbound-receipt-item-image-${item.id}'),
            title: item.itemName,
            barcode: item.barcode,
            imageUrl: item.imageUrl,
            quantityLabel: controller.quantityLabel(item),
            isMatched: controller.isItemMatched(item),
            enabled: controller.canReceiveItems,
            onTap: () {
              _detailBarcodeController.clear();
              _quantityController.clear();
              controller.openItem(item.id, openedByScan: false);
            },
          ),
          const SizedBox(height: 12),
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
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFD9E2F2)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('inbound-receipt-start-button'),
            onPressed: controller.canReceiveItems || controller.isStarting
                ? null
                : controller.startReceiving,
            child: Text(
              controller.isStarting ? 'Starting...' : 'Start receiving',
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
    return ListView(
      key: const Key('inbound-receipt-detail-page'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ReceiptInfoCard(label: 'PO', value: receipt.poNumber),
        const SizedBox(height: 12),
        _ReceiptInfoCard(label: 'Item', value: item.itemName),
        const SizedBox(height: 12),
        _ReceiptInfoCard(label: 'Barcode', value: item.barcode),
        const SizedBox(height: 12),
        _ReceiptInfoCard(
          label: 'Expected Qty',
          value: item.expectedQuantity.toString(),
        ),
        const SizedBox(height: 16),
        if (!controller.detailOpenedByScan) ...[
          TextField(
            key: const Key('inbound-receipt-detail-barcode-field'),
            controller: _detailBarcodeController,
            keyboardType: TextInputType.none,
            autofocus: true,
            onChanged: (value) {
              _detailScanDebounce?.cancel();
              _detailScanDebounce = Timer(
                const Duration(milliseconds: 150),
                () {
                  controller.validateSelectedItemBarcode(value);
                },
              );
            },
            decoration: const InputDecoration(
              labelText: 'Scan item barcode',
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('inbound-receipt-detail-quantity-field'),
          controller: _quantityController,
          enabled: quantityEnabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Received quantity',
          ),
        ),
        const SizedBox(height: 12),
        if (controller.scanErrorMessage != null) ...[
          Text(
            controller.scanErrorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('inbound-receipt-detail-confirm-button'),
            onPressed: !quantityEnabled || controller.isSubmitting
                ? null
                : () async {
                    final quantity =
                        int.tryParse(_quantityController.text) ?? 0;
                    final succeeded =
                        await controller.confirmSelectedItemQuantity(quantity);
                    if (!mounted || !succeeded) return;
                    _detailBarcodeController.clear();
                    _quantityController.clear();
                  },
            child: Text(
              controller.isSubmitting ? 'Saving...' : 'Confirm quantity',
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptInfoCard extends StatelessWidget {
  const _ReceiptInfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF5D6B82),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
    final borderColor = isMatched
        ? _InboundReceiptPageState._matchedItemBorderColor
        : const Color(0xFFD9E2F2);
    final backgroundColor = isMatched
        ? _InboundReceiptPageState._matchedItemColor
        : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          key: containerKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      barcode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5D6B82),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                quantityLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isMatched
                          ? _InboundReceiptPageState._matchedItemBorderColor
                          : null,
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
