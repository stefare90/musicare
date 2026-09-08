import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerCubit extends SafeCubit<PlayerState> {
  final AudioPlayerService _service;
  StreamSubscription<PlayerState>? _stateSub;

  PlayerCubit({required AudioPlayerService audioService})
    : _service = audioService,
      super(PlayerState.fromPlaybackData(audioService.playbackData)) {
    _stateSub = audioService.playbackDataStream
        .map(PlayerState.fromPlaybackData)
        .listen(emit);
  }

  Future<void> playTrack(Track track) => _service.playTrack(track);
  Future<void> playQueue(List<Track> queue, {int index = 0}) =>
      _service.playQueue(queue, index: index);

  Future<void> next() => _service.next();
  Future<void> previous() => _service.previous();
  Future<void> skipToIndex(int index) => _service.skipToIndex(index);
  Future<void> togglePlayPause() => _service.togglePlayPause();
  Future<void> play() => _service.play();
  Future<void> pause() => _service.pause();
  Future<void> seek(Duration position) => _service.seek(position);

  void toggleShuffle() => _service.toggleShuffle();
  void cycleRepeatMode() => _service.cycleRepeatMode();
  void addToQueue(Track track) => _service.addToQueue(track);
  void insertNext(Track track) => _service.insertNext(track);
  void removeFromQueue(int index) => _service.removeFromQueue(index);
  void reorderQueue(int oldIndex, int newIndex) =>
      _service.reorderQueue(oldIndex, newIndex);

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    return super.close();
  }
}
