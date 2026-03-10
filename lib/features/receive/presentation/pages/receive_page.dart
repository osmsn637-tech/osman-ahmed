import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:putaway_app/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:putaway_app/shared/l10n/l10n.dart';
import 'package:putaway_app/shared/scanner/scanner_provider.dart';
import 'package:putaway_app/shared/ui/location_row.dart';
import 'package:putaway_app/shared/ui/scan_box.dart';
import '../controllers/receive_controller.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key, this.initialBarcode});

  final String? initialBarcode;

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  String? _lastHandledScan;
  String? _lastSuccess;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerProvider>().init();
      final initialBarcode = widget.initialBarcode?.trim() ?? '';
      if (initialBarcode.isNotEmpty) {
        context.read<ReceiveController>().onScan(initialBarcode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final receiveController = context.watch<ReceiveController>();
    final scannerBarcode = context.select<ScannerProvider, String>((s) => s.state.lastBarcode);
    final state = receiveController.state;

    if (scannerBarcode.isNotEmpty && scannerBarcode != _lastHandledScan) {
      _lastHandledScan = scannerBarcode;
      receiveController.onScan(scannerBarcode);
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
      appBar: AppBar(title: Text(l10n.receiveTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScanBox(
              label: state.summary == null
                  ? l10n.receiveScanItemBarcode
                  : l10n.receiveScanDestinationLocation,
              subLabel: state.summary == null
                  ? l10n.receiveUsePhysicalScanner
                  : l10n.receiveConfirmDestinationThenQuantity,
              highlight: true,
            ),
            const SizedBox(height: 12),
            if (state.summary != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ItemSummaryPanel(summary: state.summary!),
                    const SizedBox(height: 12),
                    _DestinationInput(
                      code: state.destinationCode,
                      onChanged: receiveController.setDestination,
                    ),
                    const SizedBox(height: 12),
                    _QuantityInput(
                      quantity: state.quantity,
                      onChanged: receiveController.setQuantity,
                      onDefault: receiveController.setDefaultQuantity,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (state.successMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(state.successMessage!, style: TextStyle(color: Colors.green.shade700)),
                    ],
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(state.isSubmitting
                          ? l10n.receiveReceiving
                          : l10n.receiveConfirmReceive),
                      onPressed: state.isSubmitting ? null : receiveController.submit,
                    ),
                  ],
                ),
              ),
            if (state.summary == null)
              Expanded(
                child: Center(
                  child: Text(l10n.receiveAwaitingScan,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemSummaryPanel extends StatelessWidget {
  const _ItemSummaryPanel({required this.summary});

  final ItemLocationSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 220,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.itemName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(l10n.receiveSkuLabel(summary.barcode),
                style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(l10n.receiveTotalLabel(summary.totalQuantity.toString()),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: summary.locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final loc = summary.locations[index];
                  final type = loc.isShelf ? l10n.receiveShelf : l10n.receiveBulk;
                  return LocationRow(
                    code: loc.code,
                    typeLabel: type,
                    quantity: '${loc.quantity}',
                    trailing: Text(l10n.zoneWithCode(loc.zone),
                        style: TextStyle(color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationInput extends StatelessWidget {
  const _DestinationInput({required this.code, required this.onChanged});

  final String code;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: code);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.receiveDestinationLocationScan,
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
      onChanged: onChanged,
    );
  }
}

class _QuantityInput extends StatelessWidget {
  const _QuantityInput({required this.quantity, required this.onChanged, required this.onDefault});

  final String quantity;
  final ValueChanged<String> onChanged;
  final VoidCallback onDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: quantity);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.receiveQuantityToReceive,
              prefixIcon: const Icon(Icons.numbers),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onDefault,
          child: Text(l10n.receiveFullQty),
        ),
      ],
    );
  }
}
