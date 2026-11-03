import 'package:flutter/widgets.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/error_presentation.dart';
import 'package:music_are/core/notice/notice.dart';

extension ExceptionLocalizer on Object {
  String toLocalizedString(BuildContext context) =>
      sl<ErrorPresentation>().text(this, context.l10n);

  NoticeAction? noticeAction(BuildContext context) =>
      sl<ErrorPresentation>().action(this, context);

  bool get needsNotice => sl<ErrorPresentation>().needsNotice(this);
}
