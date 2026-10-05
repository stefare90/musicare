import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

/// Shows a snackbar for every notice pushed by [notices].
///
/// The only place that builds snackbars: everything else emits on the bus. A
/// failure gets the error styling, a message the neutral one; the action is
/// optional on both.
class NoticeListener extends StatefulWidget {
  final Stream<Notice> notices;

  final Widget child;

  const NoticeListener({super.key, required this.notices, required this.child});

  @override
  State<NoticeListener> createState() => _NoticeListenerState();
}

class _NoticeListenerState extends State<NoticeListener> {
  StreamSubscription<Notice>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant NoticeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.notices, widget.notices)) {
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = widget.notices.listen(_show);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// The host Scaffold keeps the app's MediaQuery untouched, so it does not
  /// lift the snackbar for the keyboard itself: do it here from the same data.
  double _keyboardInset() {
    final media = MediaQuery.of(context);
    return math.max(
      0.0,
      media.viewInsets.bottom - media.viewPadding.bottom,
    );
  }

  void _show(Notice notice) {
    if (!mounted) return;
    final keyboardInset = _keyboardInset();

    switch (notice) {
      case MessageNotice(:final message, :final action):
        Dialogs.showMessageSnackBar(
          context,
          message: message,
          actionLabel: action?.label,
          onAction: action?.onAction,
          keyboardInset: keyboardInset,
        );
      case ErrorNotice(:final error):
        final resolved = error.noticeAction(context);
        Dialogs.showErrorSnackBar(
          context,
          message: error.toLocalizedString(context),
          actionLabel: resolved?.label,
          onAction: resolved?.onAction,
          keyboardInset: keyboardInset,
        );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
