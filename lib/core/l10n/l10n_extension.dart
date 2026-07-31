import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/app_localizations.dart';

extension L10nBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
