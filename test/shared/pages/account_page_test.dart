import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/features/auth/domain/entities/user.dart';
import 'package:wherehouse/features/auth/presentation/providers/session_provider.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/shared/pages/account_page.dart';
import 'package:wherehouse/shared/providers/locale_controller.dart';

void main() {
  testWidgets('account page does not show copy action or zone details',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000001',
        name: 'Worker One',
        role: 'worker',
        phone: '966500000000',
        zone: 'Z01',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy_rounded), findsNothing);
    expect(find.text('966500000000'), findsOneWidget);
    expect(find.text('Zone Z01'), findsNothing);
    expect(find.text('Z01'), findsNothing);
    expect(find.text('Zone'), findsNothing);
  });

  testWidgets('account page shows inbound label for reciver alias',
      (tester) async {
    final session = SessionController();
    session.setUser(
      const User(
        id: '2bcf9d5d-1234-4f1d-8f6d-000000000004',
        name: 'Receiver One',
        role: 'reciver',
        phone: '966511111111',
        zone: 'Z02',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(),
          ),
        ],
        child: const MaterialApp(
          home: AccountPage(),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('INBOUND'), findsWidgets);
    expect(find.text('RECIVER'), findsNothing);
    expect(find.text('Zone Z02'), findsNothing);
    expect(find.text('Z02'), findsNothing);
  });
}
