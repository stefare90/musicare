import 'package:flutter/foundation.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';

@immutable
class PlaybackPending {
  final int nextOffset;
  final int total;
  final bool isLoading;
  final Object? error;

  const PlaybackPending({
    required this.nextOffset,
    required this.total,
    this.isLoading = false,
    this.error,
  });

  const PlaybackPending.empty()
    : nextOffset = 0,
      total = 0,
      isLoading = false,
      error = null;

  factory PlaybackPending.fromSource(PendingSource source) => PlaybackPending(
    nextOffset: source.nextOffset,
    total: source.total,
  );

  PlaybackPending started() => PlaybackPending(
    nextOffset: nextOffset,
    total: total,
    isLoading: true,
  );

  PlaybackPending advancedBy({required int loaded, required int total}) {
    final advanced = PlaybackPending(
      nextOffset: nextOffset + loaded,
      total: total,
    );
    return advanced.isEmpty ? const PlaybackPending.empty() : advanced;
  }

  PlaybackPending failed(Object e) => PlaybackPending(
    nextOffset: nextOffset,
    total: total,
    error: e,
  );

  bool get isEmpty => nextOffset >= total;
}
