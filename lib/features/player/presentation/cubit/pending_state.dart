import 'package:flutter/foundation.dart';
import 'package:music_are/features/player/data/models/playback_pending.dart';

@immutable
class PendingState {
  final int remaining;
  final bool isLoading;
  final Object? error;

  const PendingState({
    this.remaining = 0,
    this.isLoading = false,
    this.error,
  });

  factory PendingState.fromPlaybackPending(PlaybackPending raw) {
    if (raw.isEmpty && raw.error == null) return const PendingState();
    final rest = raw.total - raw.nextOffset;
    return PendingState(
      remaining: rest < 0 ? 0 : rest,
      isLoading: raw.isLoading,
      error: raw.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingState &&
          runtimeType == other.runtimeType &&
          remaining == other.remaining &&
          isLoading == other.isLoading &&
          identical(error, other.error);

  @override
  int get hashCode => Object.hash(remaining, isLoading);
}
