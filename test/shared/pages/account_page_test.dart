import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:putaway_app/features/auth/domain/entities/user.dart';
import 'package:putaway_app/features/auth/presentation/providers/session_provider.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:putaway_app/shared/pages/account_page.dart';
import 'package:putaway_app/shared/providers/locale_controller.dart';

void main() {
  testWidgets('account page does not show copy action for phone number',
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
  });
}
