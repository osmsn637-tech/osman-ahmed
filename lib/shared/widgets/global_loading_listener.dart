import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/global_loading_provider.dart';

class GlobalLoadingListener extends StatelessWidget {
  const GlobalLoadingListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GlobalLoadingController>().isLoading;
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          child,
          if (isLoading)
            const Stack(
              children: [
                ModalBarrier(
                  dismissible: false,
                  color: Color(0x44000000),
                ),
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
