import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/shared/l10n/l10n.dart';

void main() {
  testWidgets('l10n helper treats Bengali as LTR and picks Bengali text',
      (tester) async {
    late TextDirection direction;
    late String languageCode;
    late String label;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('bn')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            languageCode = context.languageCode;
            label = context.trText(
              english: 'Account',
              arabic: 'الحساب',
              bengali: 'অ্যাকাউন্ট',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(direction, TextDirection.ltr);
    expect(languageCode, 'bn');
    expect(label, 'অ্যাকাউন্ট');
  });

  testWidgets('l10n helper keeps legacy urdu alias working for Bengali',
      (tester) async {
    late String label;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('bn')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            label = context.trText(
              english: 'Account',
              arabic: 'الحساب',
              urdu: 'অ্যাকাউন্ট',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(label, 'অ্যাকাউন্ট');
  });
}
