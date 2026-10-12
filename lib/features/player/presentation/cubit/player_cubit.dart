import 'dart:async';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerCubit extends SafeCubit<PlayerState> {
  final AudioPlayerService _service;
  final NoticeBus _notices;
  StreamSubscription<PlayerState>? _stateSub;
  Object? _lastNotifiedError;
  Object? _lastPendingError;

  PlayerCubit(AudioPlayerService audioService, this._notices)
    : _service = audioService,
      super(PlayerState.fromPlaybackData(audioService.playbackData)) {
    _stateSub = audioService.playbackDataStream
        .map(PlayerState.fromPlaybackData)
        .listen(_onPlaybackData);
  }

  void _onPlaybackData(PlayerState state) {
    final error = state.error;
    if (error != null && !identical(error, _lastNotifiedError)) {
      _lastNotifiedError = error;
      _notices.emit(Notice.error(error));
    } else if (error == null) {
      _lastNotifiedError = null;
    }
    final pendingError = state.pending.error;
    if (pendingError != null) {
      if (_lastPendingError == null) {
        _lastPendingError = pendingError;
        _notices.emit(Notice.error(pendingError));
      }
    } else {
      _lastPendingError = null;
    }
    emit(state);
  }

  Future<void> playTrack(Track track) => _service.playTrack(track);
  Future<void> playQueue(
    List<Track> queue, {
    int index = 0,
    PendingSource? pending,
  }) =>
      _service.playQueue(queue, index: index, pending: pending);
  Future<void> retryPendingLoad() => _service.retryPendingLoad();

  Future<void> next() => _service.next();
  Future<void> previous() => _service.previous();
  Future<void> skipToIndex(int index) => _service.skipToIndex(index);
  Future<void> selectStreamCandidate(int candidateIndex) =>
      _service.selectStreamCandidate(candidateIndex);
  Future<void> togglePlayPause() => _service.togglePlayPause();
  Future<void> play() => _service.play();
  Future<void> pause() => _service.pause();
  Future<void> seek(Duration position) => _service.seek(position);

  void toggleShuffle() => _service.toggleShuffle();
  void cycleRepeatMode() => _service.cycleRepeatMode();
  void addToQueue(Track track) => _service.addToQueue(track);
  void insertNext(Track track) => _service.insertNext(track);
  void addAllToQueue(List<Track> tracks) => _service.addAllToQueue(tracks);
  void insertAllNext(List<Track> tracks) => _service.insertAllNext(tracks);
  void removeFromQueue(int index) => _service.removeFromQueue(index);
  void reorderQueue(int oldIndex, int newIndex) =>
      _service.reorderQueue(oldIndex, newIndex);

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    return super.close();
  }
}
