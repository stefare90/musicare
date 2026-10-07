import 'package:flutter/foundation.dart';

typedef NoticeAction = ({String label, VoidCallback onAction});

/// Closed on purpose: a new kind cannot reach the renderer unhandled. The
/// action lives on the notice, not on the error, so a message can offer one.
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

/// Plain text already localized by the emitter (which has a `BuildContext`),
/// unlike [ErrorNotice], resolved when shown.
final class MessageNotice extends Notice {
  final String message;
  final NoticeAction? action;

  const MessageNotice(this.message, {this.action});
}
