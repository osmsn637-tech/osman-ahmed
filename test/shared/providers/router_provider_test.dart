import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/shared/providers/router_provider.dart';

void main() {
  testWidgets('router excludes deleted create receipt and exceptions routes',
      (tester) async {
    final sessionController = SessionController();
    GoRouter? router;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            router ??= buildRouter(context, sessionController);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final paths = router!.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();

    expect(paths, isNot(contains('/inbound/create')));
    expect(paths, isNot(contains('/exceptions-tab')));
    expect(paths, isNot(contains('/exceptions')));
  });
}
