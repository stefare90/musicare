import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

/// Shows a snackbar for every notice pushed by [notices].
///
/// The action is optional: [PluginNoticeX.noticeAction] decides whether the
/// notice offers one, so non-auth notices can be message-only.
class NoticeListener extends StatefulWidget {
  final Stream<Object> notices;
  final Widget child;

  const NoticeListener({super.key, required this.notices, required this.child});

  @override
  State<NoticeListener> createState() => _NoticeListenerState();
}

class _NoticeListenerState extends State<NoticeListener> {
  StreamSubscription<Object>? _subscription;

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

  void _show(Object error) {
    if (!mounted) return;
    final action = error.noticeAction(context);
    Dialogs.showErrorSnackBar(
      context,
      message: error.toLocalizedString(context),
      actionLabel: action?.label,
      onAction: action?.onAction,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
