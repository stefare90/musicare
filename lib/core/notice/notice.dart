import 'package:flutter/foundation.dart';

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

  factory Notice.message(String message, {NoticeAction? action}) =
      MessageNotice;
}

final class ErrorNotice extends Notice {
  final Object error;

  const ErrorNotice(this.error);
}

/// A message already localized by the emitter (normally a widget, which has a
/// `BuildContext`).
///
/// Unlike [ErrorNotice], whose message and action are derived from the error
/// when the snackbar is shown, this one carries plain text, so the notice stays
/// a simple value.
final class MessageNotice extends Notice {
  final String message;
  final NoticeAction? action;

  const MessageNotice(this.message, {this.action});
}
