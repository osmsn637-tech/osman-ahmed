import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/features/dashboard/presentation/pages/home_page.dart';

void main() {
  testWidgets('home page renders Arabic title in Arabic locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomePage(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('عامل الترصيص'), findsOneWidget);
  });

  testWidgets('home page renders Urdu title in Urdu locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ur'),
        supportedLocales: [Locale('en'), Locale('ar'), Locale('ur')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomePage(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('پٹ اوے کارکن'), findsOneWidget);
  });
}
