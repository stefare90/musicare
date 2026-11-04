import 'package:flutter/widgets.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice.dart';

abstract interface class ErrorTable {
  ErrorSpec? describe(Object error, AppLocalizations l10n);

  bool notifies(Object error) => false;
}

class ErrorSpec {
  final String text;
  final NoticeAction Function(BuildContext)? action;
  const ErrorSpec(this.text, {this.action});
}
