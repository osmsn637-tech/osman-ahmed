import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:wherehouse/features/move/domain/entities/item_location_summary_entity.dart';
import 'package:wherehouse/shared/l10n/l10n.dart';
import 'package:wherehouse/shared/scanner/scanner_provider.dart';
import 'package:wherehouse/shared/ui/location_row.dart';
import 'package:wherehouse/shared/ui/scan_box.dart';
import '../controllers/move_controller.dart';

class MoveItemPage extends StatefulWidget {
  const MoveItemPage({super.key});

  @override
  State<MoveItemPage> createState() => _MoveItemPageState();
}

class _MoveItemPageState extends State<MoveItemPage> {
  String? _lastHandledScan;
  String? _lastSuccess;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    // Start scanner listening for this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moveController = context.watch<MoveController>();
    final scannerBarcode = context.select<ScannerProvider, String>((s) => s.state.lastBarcode);
    final state = moveController.state;

    // Auto-handle latest scan once
    if (scannerBarcode.isNotEmpty && scannerBarcode != _lastHandledScan) {
      _lastHandledScan = scannerBarcode;
      moveController.onScan(scannerBarcode);
    }

    // Feedback
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
      appBar: AppBar(title: Text(l10n.moveTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScanBox(
              label: state.summary == null
                  ? l10n.moveScanItemBarcode
                  : l10n.moveScanDestinationLocation,
              subLabel: state.summary == null
                  ? l10n.moveTriggerScannerToCaptureItem
                  : l10n.moveScanTargetLocationThenConfirm,
              highlight: true,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.summary != null) ...[
                      _MoveSection(title: l10n.moveFromLocation, child: _FromLocations(summary: state.summary!)),
                      const SizedBox(height: 12),
                      _MoveSection(title: l10n.moveItemSection, child: _ItemInfo(summary: state.summary!)),
                      const SizedBox(height: 12),
                      _MoveSection(
                        title: l10n.moveToLocation,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: l10n.moveDestinationLocationBarcode,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                          controller: TextEditingController(text: state.destinationCode),
                          onChanged: moveController.setDestination,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MoveSection(
                        title: l10n.moveQuantitySection,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: state.moveQuantity),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.moveQtyToMove,
                                  prefixIcon: const Icon(Icons.numbers),
                                ),
                                onChanged: moveController.setQuantity,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: moveController.setFullQuantity,
                              child: Text(l10n.receiveFullQty),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (state.summary == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: Text(l10n.moveAwaitingScan,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                      ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (state.successMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(state.successMessage!, style: TextStyle(color: Colors.green.shade700)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                  state.isSubmitting ? l10n.moveMoving : l10n.moveConfirmMove),
              onPressed: state.isSubmitting ? null : moveController.submitMove,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveSection extends StatelessWidget {
  const _MoveSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FromLocations extends StatelessWidget {
  const _FromLocations({required this.summary});

  final ItemLocationSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (summary.locations.isEmpty) {
      return Text(l10n.moveNoSourceLocations);
    }
    return Column(
      children: [
        for (final loc in summary.locations)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: LocationRow(
              code: loc.code,
              typeLabel: loc.isShelf ? l10n.receiveShelf : l10n.receiveBulk,
              quantity: '${loc.quantity}',
              trailing: Text(l10n.zoneWithCode(loc.zone),
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          ),
      ],
    );
  }
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.summary});

  final ItemLocationSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary.itemName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l10n.moveSkuLabel(summary.barcode),
            style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l10n.moveTotalLabel(summary.totalQuantity.toString()),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
