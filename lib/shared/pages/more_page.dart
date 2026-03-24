import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/move/presentation/pages/item_lookup_scan_dialog.dart';
import '../l10n/l10n.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.moreHome),
            onTap: () => context.go('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(l10n.moreItemLookup),
            onTap: () async {
              final barcode = await showItemLookupScanDialog(
                context,
                showKeyboard: false,
              );
              final normalized = barcode?.trim() ?? '';
              if (!context.mounted || normalized.isEmpty) return;
              context.push('/item-lookup/result/${Uri.encodeComponent(normalized)}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.moreStockAdjustment),
            onTap: () async {
              final barcode = await showItemLookupScanDialog(
                context,
                showKeyboard: false,
              );
              final normalized = barcode?.trim() ?? '';
              if (!context.mounted || normalized.isEmpty) return;
              context.push(
                '/item-lookup/result/${Uri.encodeComponent(normalized)}?mode=adjust',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: Text(l10n.moreExceptions),
            onTap: () => context.go('/exceptions'),
          ),
        ],
      ),
    );
  }
}
