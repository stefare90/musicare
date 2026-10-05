import 'package:flutter/widgets.dart';

/// Optional action a notice can offer to the user.
typedef NoticeAction = ({String label, VoidCallback onAction});

/// A transient notice travelling on the `NoticeBus`: either a failure to report
/// or a message to show.
///
/// Closed on purpose: a new kind of notice cannot reach the renderer without it
/// handling the new case. The optional action lives on the notice itself, not on
/// the error, so a message can offer one too.
sealed class Notice {
  const Notice();

  factory Notice.error(Object error) = ErrorNotice;

  factory Notice.message(
    String Function(BuildContext context) message, {
    NoticeAction Function(BuildContext context)? action,
  }) = MessageNotice;
}

final class ErrorNotice extends Notice {
  final Object error;

  const ErrorNotice(this.error);
}

final class MessageNotice extends Notice {
  /// Built lazily because the emitter (a cubit, usually) has no `BuildContext`:
  /// the message is localized when the snackbar is shown.
  final String Function(BuildContext context) message;

  final NoticeAction Function(BuildContext context)? action;

  const MessageNotice(this.message, {this.action});
}
