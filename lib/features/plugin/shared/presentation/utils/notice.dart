import 'package:flutter/widgets.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';

extension PluginNoticeX on Object {
  /// Shown even when a widget already shows it, and even with no action
  /// (e.g. a background plugin failure).
  bool get needsNotice => switch (this) {
    MetadataAuthRequiredException() => true,
    _ => false,
  };

  NoticeAction? noticeAction(BuildContext context) => switch (this) {
    MetadataAuthRequiredException() => (
      label: context.l10n.accountSignIn,
      onAction: () => MetadataAccountActions.signIn(context),
    ),
    _ => null,
  };
}
