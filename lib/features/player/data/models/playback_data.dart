import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/data/models/playback_pending.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

@immutable
class PlaybackData {
  final PlaybackQueue queue;
  final PlaybackCandidates candidates;
  final bool isPlaying;
  final PlaybackProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Object? error;
  final PlaybackPending pending;

  const PlaybackData({
    this.queue = const PlaybackQueue(),
    this.candidates = const PlaybackCandidates(),
    this.isPlaying = false,
    this.processingState = PlaybackProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.pending = const PlaybackPending.empty(),
  });

  Track? get currentTrack => queue.currentTrack;
  AudioStreamResponse? get currentStream => candidates.activeStream;

  factory PlaybackData.loading(PlaybackData current) {
    return PlaybackData(
      queue: current.queue,
      candidates: current.candidates,
      isPlaying: current.isPlaying,
      processingState: PlaybackProcessingState.loading,
      position: Duration.zero,
      duration: Duration.zero,
      pending: current.pending,
    );
  }

  factory PlaybackData.failure(PlaybackData current, Object error) {
    return PlaybackData(
      queue: current.queue,
      candidates: current.candidates,
      isPlaying: current.isPlaying,
      processingState: PlaybackProcessingState.idle,
      position: current.position,
      duration: current.duration,
      error: error,
      pending: current.pending,
    );
  }

  PlaybackData copyWith({
    PlaybackQueue? queue,
    PlaybackCandidates? candidates,
    bool? isPlaying,
    PlaybackProcessingState? processingState,
    Duration? position,
    Duration? duration,
    PlaybackPending? pending,
  }) {
    return PlaybackData(
      queue: queue ?? this.queue,
      candidates: candidates ?? this.candidates,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
      pending: pending ?? this.pending,
    );
  }
}
