import 'package:flutter/widgets.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isArabicLocale => Localizations.localeOf(this).languageCode == 'ar';
}
