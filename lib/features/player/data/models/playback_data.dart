import 'package:flutter/foundation.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';

@immutable
class PlaybackData {
  final PlaybackQueue queue;
  final bool isPlaying;
  final PlaybackProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlaybackData({
    this.queue = const PlaybackQueue(),
    this.isPlaying = false,
    this.processingState = PlaybackProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  Track? get currentTrack => queue.currentTrack;

  PlaybackData copyWith({
    PlaybackQueue? queue,
    bool? isPlaying,
    PlaybackProcessingState? processingState,
    Duration? position,
    Duration? duration,
    Object? error,
  }) {
    return PlaybackData(
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
