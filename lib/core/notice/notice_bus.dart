import 'dart:async';

/// App-wide one-shot notice channel.
///
/// Any cubit or background service can emit; a single `NoticeListener` at the
/// app root shows the snackbars, so notices surface regardless of the visible
/// route. Events emitted before the root subscribes are buffered.
class NoticeBus {
  NoticeBus() {
    _controller.onListen = _flush;
  }

  final StreamController<Object> _controller =
      StreamController<Object>.broadcast();
  final List<Object> _pending = [];

  Stream<Object> get notices => _controller.stream;

  void emit(Object error) {
    if (_controller.hasListener) {
      _controller.add(error);
    } else {
      _pending.add(error);
    }
  }

  void _flush() {
    if (_pending.isEmpty) return;
    final pending = List<Object>.of(_pending);
    _pending.clear();
    for (final error in pending) {
      _controller.add(error);
    }
  }

  Future<void> close() async {
    _controller.onListen = null;
    await _controller.close();
  }
}
