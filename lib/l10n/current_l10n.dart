import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

AppLocalizations currentL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  try {
    return lookupAppLocalizations(locale);
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}
