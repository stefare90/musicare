import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';

enum PlayerStatus {
  idle,
  resolving,
  buffering,
  playing,
  paused,
  completed,
  error,
}

class PlayerState {
  final PlayerStatus status;
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.queue = const [],
    this.currentIndex = 0,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading =>
      status == PlayerStatus.resolving || status == PlayerStatus.buffering;
  bool get hasTrack => currentTrack != null;
  bool get hasNext =>
      queue.isNotEmpty &&
      (repeatMode == RepeatMode.all ||
          repeatMode == RepeatMode.one ||
          currentIndex + 1 < queue.length);
  bool get hasPrevious =>
      queue.isNotEmpty &&
      (repeatMode == RepeatMode.all ||
          currentIndex > 0 ||
          position.inSeconds > 3);

  PlayerState copyWith({
    PlayerStatus? status,
    Track? currentTrack,
    List<Track>? queue,
    int? currentIndex,
    bool? isShuffled,
    RepeatMode? repeatMode,
    Duration? position,
    Duration? duration,
    Object? error,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
