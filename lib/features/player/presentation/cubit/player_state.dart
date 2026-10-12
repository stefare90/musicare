import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/presentation/cubit/candidates_state.dart';
import 'package:music_are/features/player/presentation/cubit/pending_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class PlayerState {
  final QueueState queue;
  final CandidatesState candidates;
  final PendingState pending;
  final bool isPlaying;
  final PlaybackProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlayerState({
    this.queue = const QueueState(),
    this.candidates = const CandidatesState(),
    this.pending = const PendingState(),
    this.isPlaying = false,
    this.processingState = PlaybackProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  factory PlayerState.fromPlaybackData(PlaybackData data) {
    return PlayerState(
      queue: QueueState.fromPlaybackQueue(data.queue),
      candidates: CandidatesState.fromPlaybackCandidates(data.candidates),
      pending: PendingState.fromPlaybackPending(data.pending),
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
  AudioStreamResponse? get currentStream => candidates.activeStream;

  double get positionMs => position.inMilliseconds.toDouble();
  double get durationMs => duration.inMilliseconds.toDouble();
  double get maxSlider => durationMs > 0 ? durationMs : 1.0;

  String get formattedPosition => formatDuration(position);
  String get formattedDuration => formatDuration(duration);

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
