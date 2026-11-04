import 'dart:async';
import 'dart:io';

import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/errors/error_table.dart';

class SystemErrorTable implements ErrorTable {
  const SystemErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) => switch (error) {
    SocketException(:final message) => ErrorSpec(
      '${l10n.pluginErrorNetwork}: $message',
    ),
    TimeoutException() => ErrorSpec(l10n.pluginErrorTimeout),
    _ => null,
  };

  @override
  bool notifies(Object error) => false;
}
