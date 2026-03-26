import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../controllers/app_update_controller.dart';

class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({
    required this.state,
    this.onUpdatePressed,
    super.key,
  });

  final AppUpdateState state;
  final Future<bool> Function()? onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    final updateEnabled =
        state.downloadUrl.isNotEmpty && onUpdatePressed != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.system_update_alt_rounded,
                        size: 56,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Update Required',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This Android build is no longer supported. Install the latest version to continue.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      _VersionRow(
                        label: 'Current version',
                        value: state.installedVersion.isEmpty
                            ? '--'
                            : state.installedVersion,
                      ),
                      const SizedBox(height: 10),
                      _VersionRow(
                        label: 'Required version',
                        value: state.minimumSupportedVersion.isEmpty
                            ? '--'
                            : state.minimumSupportedVersion,
                      ),
                      if ((state.releaseNotes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          state.releaseNotes!.trim(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: updateEnabled
                              ? () async {
                                  await onUpdatePressed!.call();
                                }
                              : null,
                          child: const Text('Update App'),
                        ),
                      ),
                      if (!updateEnabled) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Update link unavailable. Please contact support.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
