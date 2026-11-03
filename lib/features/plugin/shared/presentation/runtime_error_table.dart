import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/error_table.dart';

class RuntimeErrorTable implements ErrorTable {
  const RuntimeErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    if (error is! RuntimeHostException) return null;
    return switch (error) {
      RuntimeBootTimeoutException() => ErrorSpec(l10n.pluginErrorTimeout),
      RuntimeNotStartedException() => null,
      PluginInstallException() => null,
    };
  }

  @override
  bool notifies(Object error) => false;
}
