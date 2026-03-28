import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wherehouse/shared/l10n/l10n.dart';

void main() {
  testWidgets('l10n helper treats Urdu as RTL and picks Urdu text',
      (tester) async {
    late bool isRtl;
    late String languageCode;
    late String label;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ur'),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('ur')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            isRtl = context.isRtlLocale;
            languageCode = context.languageCode;
            label = context.trText(
              english: 'Account',
              arabic: 'الحساب',
              urdu: 'اکاؤنٹ',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(isRtl, isTrue);
    expect(languageCode, 'ur');
    expect(label, 'اکاؤنٹ');
  });
}
