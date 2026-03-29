import 'package:flutter/widgets.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String get languageCode => Localizations.localeOf(this).languageCode;

  bool get isArabicLocale => languageCode == 'ar';

  bool get isBengaliLocale => languageCode == 'bn';

  bool get isRtlLocale => isArabicLocale;

  String trText({
    required String english,
    required String arabic,
    String? urdu,
  }) {
    return switch (languageCode) {
      'ar' => arabic,
      'bn' => urdu ?? english,
      _ => english,
    };
  }
}
