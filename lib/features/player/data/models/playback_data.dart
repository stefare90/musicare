import 'package:flutter/foundation.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

@immutable
class PlaybackData {
  final PlaybackQueue queue;
  final PlaybackCandidates candidates;
  final bool isPlaying;
  final PlaybackProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlaybackData({
    this.queue = const PlaybackQueue(),
    this.candidates = const PlaybackCandidates(),
    this.isPlaying = false,
    this.processingState = PlaybackProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  Track? get currentTrack => queue.currentTrack;
  AudioStreamResponse? get currentStream => candidates.activeStream;

  PlaybackData copyWith({
    PlaybackQueue? queue,
    PlaybackCandidates? candidates,
    bool? isPlaying,
    PlaybackProcessingState? processingState,
    Duration? position,
    Duration? duration,
    Object? error,
  }) {
    return PlaybackData(
      queue: queue ?? this.queue,
      candidates: candidates ?? this.candidates,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
