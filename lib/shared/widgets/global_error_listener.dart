import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../providers/global_error_provider.dart';

class GlobalErrorListener extends StatelessWidget {
  const GlobalErrorListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: context.watch<GlobalErrorController>(),
      builder: (context, _) {
        final error = context.read<GlobalErrorController>().error;
        if (error != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text(error.message)),
              );
            }
            context.read<GlobalErrorController>().clear();
          });
        }
        return child;
      },
    );
  }
}
