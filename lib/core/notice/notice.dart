import 'package:flutter/foundation.dart';

typedef NoticeAction = ({String label, VoidCallback onAction});

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

final class MessageNotice extends Notice {
  final String message;
  final NoticeAction? action;

  const MessageNotice(this.message, {this.action});
}
