import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/errors/error_table.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class PluginErrorTable implements ErrorTable {
  const PluginErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    if (error is! PluginException) return null;
    return switch (error) {
      PluginNotLoadedException() => ErrorSpec(l10n.pluginErrorNotLoaded),
      PluginFileNotFoundException() => ErrorSpec(l10n.pluginErrorNotFound),
      InvalidPluginArchiveException() => ErrorSpec(
        l10n.pluginErrorInvalidArchive,
      ),
      IncompatibleSdkVersionException() => ErrorSpec(
        l10n.pluginErrorIncompatibleSdkVersion,
      ),
      InvalidPluginTypeException() => ErrorSpec(l10n.pluginErrorInvalidType),
      PluginDownloadException() => ErrorSpec(l10n.pluginErrorDownloadFailed),
      PluginSearchException(:final statusCode)
          when statusCode == 403 || statusCode == 429 =>
        ErrorSpec(l10n.pluginErrorRateLimited),
      PluginQuotaExceededException() => ErrorSpec(l10n.pluginErrorRateLimited),
      PluginSearchException() => ErrorSpec(l10n.pluginErrorNetwork),
      PluginErrorNoContext() => ErrorSpec(l10n.pluginErrorNoContext),
      StreamResolutionException() => ErrorSpec(
        l10n.pluginErrorStreamResolution,
      ),
      MetadataRadioEmptyException() => ErrorSpec(l10n.radioNoMatches),
      PluginActivationException() => ErrorSpec(
        l10n.pluginErrorInternal(error.toString()),
      ),
      PendingLoadException() => ErrorSpec(
        l10n.pluginErrorInternal(error.toString()),
      ),
    };
  }

  @override
  bool notifies(Object error) => false;
}
