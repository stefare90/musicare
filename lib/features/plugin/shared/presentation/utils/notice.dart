import 'package:flutter/widgets.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';

/// The two independent questions a notice answers: does it need to be shown,
/// and does it offer an action.
extension PluginNoticeX on Object {
  /// Whether the error must be announced with a snackbar — even when a widget
  /// already shows it, and even when it carries no action (e.g. a background
  /// plugin failure).
  bool get needsNotice => switch (this) {
    MetadataAuthRequiredException() => true,
    _ => false,
  };

  /// The action the snackbar can offer, or null for a message-only notice.
  NoticeAction? noticeAction(BuildContext context) => switch (this) {
    MetadataAuthRequiredException() => (
      label: context.l10n.accountSignIn,
      onAction: () => MetadataAccountActions.signIn(context),
    ),
    _ => null,
  };
}
