import 'package:flutter/widgets.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/error_table.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/core/notice/rethrown_error.dart';

class ErrorPresentation {
  const ErrorPresentation(this.tables);

  final List<ErrorTable> tables;

  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    final target = _unwrap(error);
    final spec = _fromTables(target, l10n);
    final wrapper = identical(target, error) ? null : _fromTables(error, l10n);
    final action = wrapper?.action ?? spec?.action;
    if (spec == null && action == null) return null;
    return ErrorSpec(
      spec?.text ?? l10n.pluginErrorUnknown(_shortLabel(target)),
      action: action,
    );
  }

  String text(Object error, AppLocalizations l10n) =>
      describe(error, l10n)?.text ??
      l10n.pluginErrorUnknown(_shortLabel(_unwrap(error)));

  NoticeAction? action(Object error, BuildContext context) =>
      describe(error, context.l10n)?.action?.call(context);

  bool needsNotice(Object error) {
    var target = error;
    while (true) {
      if (tables.any((table) => table.notifies(target))) return true;
      if (target is! RethrownError) return false;
      target = target.rethrown;
    }
  }

  ErrorSpec? _fromTables(Object error, AppLocalizations l10n) {
    for (final table in tables) {
      final spec = table.describe(error, l10n);
      if (spec != null) return spec;
    }
    return null;
  }

  Object _unwrap(Object error) {
    var target = error;
    while (target is RethrownError) {
      target = target.rethrown;
    }
    return target;
  }

  String _shortLabel(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
