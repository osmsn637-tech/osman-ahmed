import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../controllers/dashboard_controller.dart';
import '../state/dashboard_state.dart';

class ExceptionsPage extends StatelessWidget {
  const ExceptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<DashboardController>();
    final DashboardState state = controller.state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exceptionsTitle)),
      body: RefreshIndicator(
        onRefresh: () => controller.load(force: true),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.exceptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ex = state.exceptions[index];
            return Card(
              child: ListTile(
                title: Text(ex.itemName),
                subtitle: Text(l10n.exceptionsExpected(ex.expectedLocation)),
                trailing: Text(ex.status.toUpperCase(), style: const TextStyle(color: Colors.red)),
              ),
            );
          },
        ),
      ),
    );
  }
}
