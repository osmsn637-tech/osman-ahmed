import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/move/presentation/pages/item_lookup_scan_dialog.dart';

import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/inbound/domain/usecases/scan_inbound_receipt_usecase.dart';
import 'package:wherehouse/shared/l10n/l10n.dart';
import 'package:wherehouse/shared/theme/app_theme.dart';
import 'package:wherehouse/shared/widgets/app_logo.dart';

class InboundHomePage extends StatelessWidget {
  const InboundHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<SessionController, User?>(
      (session) => session.state.user,
    );
    final userName = user?.name ??
        context.trText(
          english: 'Inbound',
          arabic: 'الوارد',
          urdu: 'وصولی',
        );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 24),
            const SizedBox(width: 8),
            Text(
              context.trText(
                english: 'Inbound',
                arabic: 'الوارد',
                urdu: 'وصولی',
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6EEF8), AppTheme.surface],
                stops: [0, 0.38],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _InboundOverviewPanel(workerName: userName),
                    const SizedBox(height: 12),
                    _InboundQuickActionButton(
                      icon: Icons.search_rounded,
                      label: l10n.workerLookup,
                      onPressed: () => _openLookup(context),
                    ),
                    const SizedBox(height: 12),
                    _InboundQuickActionButton(
                      icon: Icons.call_received_rounded,
                      label: l10n.inboundReceive,
                      onPressed: () => _openReceive(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReceive(BuildContext context) async {
    final po = await showItemLookupScanDialog(
      context,
      title: context.trText(
        english: 'Scan PO',
        arabic: 'مسح أمر الشراء',
        urdu: 'پی او اسکین کریں',
      ),
      hintText: 'PO.00..',
      emptyErrorMessage: context.trText(
        english: 'Enter a valid PO',
        arabic: 'أدخل أمر شراء صالح',
        urdu: 'درست پی او درج کریں',
      ),
      continueLabel: context.trText(
        english: 'Continue',
        arabic: 'متابعة',
        urdu: 'جاری رکھیں',
      ),
      showKeyboard: false,
    );
    final normalized = po?.trim() ?? '';
    if (!context.mounted || normalized.isEmpty) return;
    final scanUseCase = context.read<ScanInboundReceiptUseCase>();
    final result = await scanUseCase.execute(normalized);
    result.when(
      success: (scan) {
        if (!context.mounted) return;
        context.push(
          '/inbound/receipt/${Uri.encodeComponent(scan.receiptId)}',
          extra: scan,
        );
      },
      failure: (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLookup(BuildContext context) async {
    final barcode = await showItemLookupScanDialog(
      context,
      showKeyboard: false,
    );
    final normalized = barcode?.trim() ?? '';
    if (!context.mounted || normalized.isEmpty) return;
    context.push('/item-lookup/result/${Uri.encodeComponent(normalized)}');
  }
}

class _InboundOverviewPanel extends StatelessWidget {
  const _InboundOverviewPanel({required this.workerName});

  final String workerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF184E77)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0D3B66),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workerWelcomeBack(workerName),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.workerTrackQueue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InboundQuickActionButton extends StatelessWidget {
  const _InboundQuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
