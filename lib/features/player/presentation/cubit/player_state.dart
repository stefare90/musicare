import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';

class PlayerState {
  final QueueState queue;
  final bool isPlaying;
  final PlaybackProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlayerState({
    this.queue = const QueueState(),
    this.isPlaying = false,
    this.processingState = PlaybackProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  factory PlayerState.fromPlaybackData(PlaybackData data) {
    return PlayerState(
      queue: QueueState.fromPlaybackQueue(data.queue),
      isPlaying: data.isPlaying,
      processingState: data.processingState,
      position: data.position,
      duration: data.duration,
      error: data.error,
    );
  }

  bool get isLoading => processingState == PlaybackProcessingState.loading;

  bool get hasTrack => queue.currentTrack != null;
  Track? get currentTrack => queue.currentTrack;

  String get formattedPosition => _formatDuration(position);
  String get formattedDuration => _formatDuration(duration);

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  PlayerState copyWith({
    QueueState? queue,
    bool? isPlaying,
    PlaybackProcessingState? processingState,
    Duration? position,
    Duration? duration,
    Object? error,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
