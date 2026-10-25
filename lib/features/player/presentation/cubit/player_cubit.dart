import 'dart:async';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class PlayerCubit extends SafeCubit<PlayerState> {
  final AudioPlayerService _service;
  final NoticeBus _notices;
  final MediaRepository _media;
  final UserSession _user;
  final PreferencesService _preferences;
  StreamSubscription<PlayerState>? _stateSub;
  Object? _lastNotifiedError;
  Object? _lastPendingError;

  PlaybackProcessingState _lastProcessingState = PlaybackProcessingState.idle;
  bool _radioInFlight = false;

  PlayerCubit(
    AudioPlayerService audioService,
    this._notices, {
    required this._media,
    required this._user,
    required this._preferences,
  }) : _service = audioService,
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
    _maybeContinueRadio(state);
  }

  Future<void> playTrack(Track track) => _service.playTrack(track);

  Future<void> playQueue(
    List<Track> queue, {
    int index = 0,
    PendingSource? pending,
  }) => _service.playQueue(queue, index: index, pending: pending);

  Future<void> retryPendingLoad() => _service.retryPendingLoad();

  Future<void> startRadio(Track seed) async {
    if (!_user.isAuthenticated) {
      _notices.emit(Notice.error(const MetadataAuthRequiredException('')));
      return;
    }
    try {
      final batch = await _media.radio(seed.id);
      final fresh = _unseen(batch, {seed.id});
      if (fresh.isEmpty) {
        _notices.emit(Notice.error(const MetadataRadioEmptyException()));
        return;
      }
      await playQueue([seed, ...fresh]);
    } catch (error) {
      _notices.emit(Notice.error(error));
    }
  }

  Future<void> next() => _service.next();

  void _maybeContinueRadio(PlayerState state) {
    final previous = _lastProcessingState;
    _lastProcessingState = state.processingState;
    if (state.processingState != PlaybackProcessingState.completed) return;
    if (previous == PlaybackProcessingState.completed) return;
    final track = state.currentTrack;
    if (track == null || state.queue.hasNext) return;
    unawaited(_continueRadio(track));
  }

  Future<void> _continueRadio(Track seed) async {
    if (await _extendWithRadio(seed)) {
      await _service.next();
    } else {
      await _service.rewindAndPause();
    }
  }

  Future<bool> _extendWithRadio(Track seed) async {
    if (!_user.isAuthenticated) return false;
    if (!(_preferences.getInfiniteMusic() ?? true)) return false;
    if (_radioInFlight) return false;

    _radioInFlight = true;
    try {
      final batch = await _media.radio(seed.id);
      if (isClosed) return false;
      final queue = _service.playbackData.queue;
      if (queue.currentTrack?.id != seed.id) return false;
      final fresh = _unseen(batch, queue.tracks.map((t) => t.id).toSet());
      if (fresh.isEmpty) return false;
      _service.addAllToQueue(fresh);
      return true;
    } catch (_) {
      return false;
    } finally {
      _radioInFlight = false;
    }
  }

  static List<Track> _unseen(List<Track> candidates, Set<String> seen) {
    final fresh = <Track>[];
    for (final track in candidates) {
      if (seen.add(track.id)) fresh.add(track);
    }
    return fresh;
  }

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
