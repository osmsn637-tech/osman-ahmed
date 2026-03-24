import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:wherehouse/shared/l10n/l10n.dart';
import 'package:wherehouse/shared/scanner/scanner_provider.dart';
import '../controllers/stock_adjustment_controller.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  String? _lastHandledScan;
  String? _lastSuccess;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<StockAdjustmentController>();
    final scannerBarcode = context.select<ScannerProvider, String>((s) => s.state.lastBarcode);
    final state = controller.state;

    if (scannerBarcode.isNotEmpty && scannerBarcode != _lastHandledScan) {
      _lastHandledScan = scannerBarcode;
      controller.handleScan(scannerBarcode);
    }

    if (state.successMessage != null && state.successMessage != _lastSuccess) {
      _lastSuccess = state.successMessage;
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
    if (state.errorMessage != null && state.errorMessage != _lastError) {
      _lastError = state.errorMessage;
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockAdjustmentTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScanBanner(
                text: state.itemId.isEmpty
                    ? l10n.stockScanItemBarcode
                    : (state.locationId.isEmpty
                        ? l10n.stockScanLocationBarcode
                        : l10n.stockReadyToSubmit),
                highlight: true,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.stockLocationBarcode,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                keyboardType: TextInputType.number,
                onChanged: controller.updateLocationId,
                controller: TextEditingController(text: state.locationId),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.stockNewQuantity,
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                onChanged: controller.updateQuantity,
                controller: TextEditingController(text: state.newQuantity),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.stockReason,
                  prefixIcon: const Icon(Icons.notes),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: state.reason,
                    items: controller.reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) controller.updateReason(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (state.successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.successMessage!,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(state.isSubmitting
                      ? l10n.stockSubmitting
                      : l10n.stockSubmitAdjustment),
                  onPressed: state.isSubmitting ? null : controller.submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner({required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? Colors.blue.shade200 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
