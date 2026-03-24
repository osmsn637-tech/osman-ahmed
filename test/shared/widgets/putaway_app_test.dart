import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/shared/providers/global_error_provider.dart';
import 'package:wherehouse/shared/providers/global_loading_provider.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';
import 'package:wherehouse/shared/widgets/putaway_app.dart';

void main() {
  testWidgets('putaway app replaces the current route with worker home when app resumes',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/move',
      routes: [
        GoRoute(
          path: '/move',
          builder: (context, state) => const Scaffold(
            body: Text('Move Page'),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Worker Home'),
          ),
        ),
      ],
    );
    final session = SessionController()
      ..setUser(
        const User(
          id: 'worker-1',
          name: 'Worker',
          role: 'worker',
          phone: '555',
          zone: 'A1',
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoRouter>.value(value: router),
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<GlobalLoadingController>(
            create: (_) => GlobalLoadingController(),
          ),
          ChangeNotifierProvider<GlobalErrorController>(
            create: (_) => GlobalErrorController(),
          ),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const PutawayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Move Page'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/move');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Worker Home'), findsOneWidget);
    expect(find.text('Move Page'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });
}
