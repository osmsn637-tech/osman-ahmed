import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:putaway_app/features/dashboard/presentation/pages/home_page.dart';

void main() {
  testWidgets('home page renders Arabic title in Arabic locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('en'), Locale('ar')],
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
}
