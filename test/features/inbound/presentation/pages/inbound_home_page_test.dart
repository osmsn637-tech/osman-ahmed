import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/features/dashboard/data/repositories/task_repository_mock.dart';
import 'package:putaway_app/features/dashboard/domain/usecases/route_task_from_event_usecase.dart';
import 'package:putaway_app/features/inbound/data/repositories/inbound_repository_mock.dart';
import 'package:putaway_app/features/inbound/presentation/controllers/inbound_controller.dart';
import 'package:putaway_app/features/inbound/presentation/pages/inbound_home_page.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  MultiProvider buildInboundProviders(
    SessionController session,
    InboundController inboundController,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider<InboundController>.value(
            value: inboundController),
      ],
      child: const InboundHomePage(),
    );
  }

  testWidgets('inbound home shows only the three action buttons', (
    tester,
  ) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000002',
        name: 'Inbound',
        role: 'inbound',
        phone: '2220000000',
        zone: 'Z01',
      ),
    );
    final inboundController = InboundController(
      InboundRepositoryMock(RouteTaskFromEventUseCase(TaskRepositoryMock())),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              buildInboundProviders(session, inboundController),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('INBOUND OPERATIONS'), findsOneWidget);
    expect(find.text('Choose your next warehouse action'), findsOneWidget);
    expect(find.text('Create Receipt'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);

    expect(find.text('Start'), findsNothing);
    expect(find.text('Complete'), findsNothing);
    expect(find.text('View'), findsNothing);
  });

  testWidgets('create receipt opens create page directly without popup', (
    tester,
  ) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000002',
        name: 'Inbound',
        role: 'inbound',
        phone: '2220000000',
        zone: 'Z01',
      ),
    );
    final inboundController = InboundController(
      InboundRepositoryMock(RouteTaskFromEventUseCase(TaskRepositoryMock())),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              buildInboundProviders(session, inboundController),
        ),
        GoRoute(
          path: '/inbound/create',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Create Page'))),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Receipt'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Create Page'), findsOneWidget);
  });
}
