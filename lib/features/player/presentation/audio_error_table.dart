import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/error_table.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class AudioErrorTable implements ErrorTable {
  const AudioErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    if (error is PendingLoadException) {
      return ErrorSpec(
        l10n.pluginErrorUnknown(error.toString()),
        action: (context) => (
          label: context.l10n.retry,
          onAction: () => context.read<PlayerCubit>().retryPendingLoad(),
        ),
      );
    }
    if (error is! AudioPluginException) return null;
    return switch (error) {
      AudioNotFoundException() => null,
      AudioRateLimitedException() => null,
      AudioTransportException() => null,
      AudioInvalidArgumentException() => null,
      AudioUnsupportedException() => null,
      AudioInternalException() => null,
    };
  }

  @override
  bool notifies(Object error) => error is PendingLoadException;
}
