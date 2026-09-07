import 'package:gyawun_metadata_sdk/metadata/models/track.dart';

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
  final Duration position;
  final Duration duration;
  final Object? error;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading =>
      status == PlayerStatus.resolving || status == PlayerStatus.buffering;
  bool get hasTrack => currentTrack != null;

  PlayerState copyWith({
    PlayerStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    Object? error,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
