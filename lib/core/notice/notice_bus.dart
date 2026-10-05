import 'dart:async';

import 'package:music_are/core/notice/notice.dart';

export 'package:music_are/core/notice/notice.dart';

/// App-wide one-shot notice channel.
///
/// Any cubit or background service can emit; a single `NoticeListener` at the
/// app root shows the snackbars, so notices surface regardless of the visible
/// route. Events emitted before the root subscribes are buffered.
class NoticeBus {
  NoticeBus() {
    _controller.onListen = _flush;
  }

  final StreamController<Notice> _controller =
      StreamController<Notice>.broadcast();
  final List<Notice> _pending = [];

  Stream<Notice> get notices => _controller.stream;

  void emit(Notice notice) {
    if (_controller.hasListener) {
      _controller.add(notice);
    } else {
      _pending.add(notice);
    }
  }

  void _flush() {
    if (_pending.isEmpty) return;
    final pending = List<Notice>.of(_pending);
    _pending.clear();
    for (final notice in pending) {
      _controller.add(notice);
    }
  }

  Future<void> close() async {
    _controller.onListen = null;
    await _controller.close();
  }
}
