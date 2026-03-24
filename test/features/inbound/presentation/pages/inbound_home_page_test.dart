import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/features/inbound/domain/usecases/scan_inbound_receipt_usecase.dart';
import 'package:wherehouse/features/inbound/presentation/controllers/inbound_controller.dart';
import 'package:wherehouse/features/inbound/presentation/pages/inbound_home_page.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  MultiProvider buildInboundProviders(
    SessionController session,
    InboundController inboundController,
    ScanInboundReceiptUseCase scanUseCase,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider<InboundController>.value(
          value: inboundController,
        ),
        Provider<ScanInboundReceiptUseCase>.value(value: scanUseCase),
      ],
      child: const InboundHomePage(),
    );
  }

  Future<void> pumpInboundHome(
    WidgetTester tester, {
    required GoRouter router,
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await pumpUi(tester);
  }

  Future<void> submitScanDialog(
    WidgetTester tester, {
    required String value,
  }) async {
    await tester.enterText(
      find.byKey(const Key('scan_barcode_field')),
      '$value\n',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('inbound home shows the receive and lookup actions', (
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
    final repository = FakeInboundRepository();
    final inboundController = InboundController(repository);
    final scanUseCase = ScanInboundReceiptUseCase(repository);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              buildInboundProviders(session, inboundController, scanUseCase),
        ),
      ],
    );

    await pumpInboundHome(tester, router: router);

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);
    expect(find.text('Create Receipt'), findsNothing);
  });

  testWidgets('receive scan routes to the inbound receipt page',
      (tester) async {
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
    final repository = FakeInboundRepository();
    final inboundController = InboundController(repository);
    final scanUseCase = ScanInboundReceiptUseCase(repository);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              buildInboundProviders(session, inboundController, scanUseCase),
        ),
        GoRoute(
          path: '/receive',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text(
                'Receive ${state.uri.queryParameters['barcode']}',
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/inbound/receipt/:id',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('Receipt ${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );

    await pumpInboundHome(tester, router: router);

    await tester.tap(find.text('Receive'));
    await pumpUi(tester);
    await submitScanDialog(tester, value: 'RCV-1001');

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/inbound/receipt/receipt-1001',
    );
  });

  testWidgets('lookup scan still routes to item lookup result', (tester) async {
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
    final repository = FakeInboundRepository();
    final inboundController = InboundController(repository);
    final scanUseCase = ScanInboundReceiptUseCase(repository);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              buildInboundProviders(session, inboundController, scanUseCase),
        ),
        GoRoute(
          path: '/item-lookup/result/:barcode',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('Lookup ${state.pathParameters['barcode']}'),
            ),
          ),
        ),
      ],
    );

    await pumpInboundHome(tester, router: router);

    await tester.tap(find.text('Lookup'));
    await pumpUi(tester);
    await submitScanDialog(tester, value: 'ITEM-2001');

    expect(find.text('Lookup ITEM-2001'), findsOneWidget);
  });
}
