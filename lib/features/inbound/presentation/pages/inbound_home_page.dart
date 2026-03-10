import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:putaway_app/features/move/presentation/pages/item_lookup_scan_dialog.dart';
import 'package:provider/provider.dart';

import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/shared/l10n/l10n.dart';
import 'package:putaway_app/shared/theme/app_theme.dart';
import 'package:putaway_app/shared/ui/action_button.dart';

class InboundHomePage extends StatelessWidget {
  const InboundHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName =
        context.select<SessionController, String?>((s) => s.state.user?.name) ??
            'Inbound';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inboundTitle)),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F0F8), AppTheme.surface],
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
                    _WelcomeBackCard(userName: userName),
                    const SizedBox(height: 14),
                    ActionButton(
                      label: 'Create Receipt',
                      icon: Icons.note_add_rounded,
                      color: AppTheme.primary,
                      onTap: () => _openCreateInbound(context),
                      height: 72,
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: 'Receive',
                      icon: Icons.call_received_rounded,
                      color: AppTheme.accent,
                      onTap: () => _openReceive(context),
                      height: 72,
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: 'Lookup',
                      icon: Icons.search_rounded,
                      color: AppTheme.success,
                      onTap: () => _openLookup(context),
                      height: 72,
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

  Future<void> _openCreateInbound(BuildContext context) async {
    final po = await showItemLookupScanDialog(
      context,
      title: 'Scan PO',
      hintText: 'PO.00..',
      emptyErrorMessage: 'Enter a valid PO',
      continueLabel: 'Continue',
      showKeyboard: false,
    );
    final normalized = po?.trim() ?? '';
    if (!context.mounted || normalized.isEmpty) return;
    context.push('/inbound/create?po=${Uri.encodeComponent(normalized)}');
  }

  Future<void> _openReceive(BuildContext context) async {
    final po = await showItemLookupScanDialog(
      context,
      title: 'Scan PO',
      hintText: 'PO.00..',
      emptyErrorMessage: 'Enter a valid PO',
      continueLabel: 'Continue',
      showKeyboard: false,
    );
    final normalized = po?.trim() ?? '';
    if (!context.mounted || normalized.isEmpty) return;
    context.push('/receive?barcode=${Uri.encodeComponent(normalized)}');
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

class _WelcomeBackCard extends StatelessWidget {
  const _WelcomeBackCard({required this.userName});

  final String userName;

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
            l10n.workerWelcomeBack(userName),
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
