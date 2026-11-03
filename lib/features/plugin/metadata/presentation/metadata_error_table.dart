import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/error_table.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_account_actions.dart';

class MetadataErrorTable implements ErrorTable {
  const MetadataErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    if (error is! MetadataPluginException) return null;
    return switch (error) {
      MetadataAuthRequiredException() => ErrorSpec(
        l10n.pluginErrorAuthRequired,
        action: (context) => (
          label: context.l10n.accountSignIn,
          onAction: () =>
              PluginAccountActions.signIn(context, PluginType.metadata),
        ),
      ),
      MetadataNotFoundException() => ErrorSpec(
        l10n.pluginErrorResourceNotFound,
      ),
      MetadataRateLimitedException() => ErrorSpec(l10n.pluginErrorRateLimited),
      MetadataTransportException(:final message) => ErrorSpec(
        '${l10n.pluginErrorNetwork}: $message',
      ),
      MetadataInvalidArgumentException() => ErrorSpec(
        l10n.pluginErrorInvalidArgument,
      ),
      MetadataUnsupportedException() => ErrorSpec(l10n.pluginErrorUnsupported),
      MetadataInternalException(:final message) => ErrorSpec(
        l10n.pluginErrorInternal(message),
      ),
    };
  }

  @override
  bool notifies(Object error) => error is MetadataAuthRequiredException;
}
