import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_account_actions.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

extension PluginNoticeX on Object {
  /// Shown even when a widget already shows it, and even with no action
  /// (e.g. a background plugin failure).
  bool get needsNotice => switch (this) {
    MetadataAuthRequiredException() => true,
    PendingLoadException() => true,
    _ => false,
  };

  NoticeAction? noticeAction(BuildContext context) => switch (this) {
    MetadataAuthRequiredException() => (
      label: context.l10n.accountSignIn,
      onAction: () => PluginAccountActions.signIn(context, PluginType.metadata),
    ),
    PendingLoadException() => (
      label: context.l10n.retry,
      onAction: () => context.read<PlayerCubit>().retryPendingLoad(),
    ),
    _ => null,
  };
}
