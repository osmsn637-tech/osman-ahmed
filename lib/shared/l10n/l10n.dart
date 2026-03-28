import 'package:flutter/widgets.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String get languageCode => Localizations.localeOf(this).languageCode;

  bool get isArabicLocale => languageCode == 'ar';

  bool get isUrduLocale => languageCode == 'ur';

  bool get isRtlLocale => isArabicLocale || isUrduLocale;

  String trText({
    required String english,
    required String arabic,
    String? urdu,
  }) {
    return switch (languageCode) {
      'ar' => arabic,
      'ur' => urdu ?? english,
      _ => english,
    };
  }
}
