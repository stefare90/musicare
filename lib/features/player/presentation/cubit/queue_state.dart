import 'package:flutter/foundation.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';

@immutable
class QueueState {
  final List<Track> tracks;
  final int currentIndex;
  final bool isShuffled;
  final PlaybackRepeatMode repeatMode;
  final bool hasNext;
  final bool hasPrevious;

  const QueueState({
    this.tracks = const [],
    this.currentIndex = 0,
    this.isShuffled = false,
    this.repeatMode = PlaybackRepeatMode.off,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  factory QueueState.fromPlaybackQueue(PlaybackQueue queue) {
    return QueueState(
      tracks: queue.tracks,
      currentIndex: queue.currentIndex,
      isShuffled: queue.isShuffled,
      repeatMode: queue.repeatMode,
      hasNext: queue.hasNext,
      hasPrevious: queue.hasPrevious,
    );
  }

  int get length => tracks.length;
  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;

  Track? get currentTrack {
    if (isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueState &&
          runtimeType == other.runtimeType &&
          currentIndex == other.currentIndex &&
          isShuffled == other.isShuffled &&
          repeatMode == other.repeatMode &&
          hasNext == other.hasNext &&
          hasPrevious == other.hasPrevious &&
          listEquals(tracks, other.tracks);

  @override
  int get hashCode => Object.hash(
    currentIndex,
    isShuffled,
    repeatMode,
    hasNext,
    hasPrevious,
    Object.hashAll(tracks),
  );
}
