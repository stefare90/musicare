import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerCubit extends SafeCubit<PlayerState> {
  final AudioPlayerService _audioService;
  final AudioStreamResolver _resolver;
  final PlaybackQueue _queue;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  DateTime _lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  PlayerCubit({
    required AudioPlayerService audioService,
    required AudioStreamResolver resolver,
    PlaybackQueue? queue,
  }) : _audioService = audioService,
       _resolver = resolver,
       _queue = queue ?? PlaybackQueue(),
       super(const PlayerState()) {
    _initAudioStreams();
  }

  void _initAudioStreams() {
    _positionSub = _audioService.positionStream.listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastPositionUpdate).inMilliseconds >= 250 ||
          pos == Duration.zero) {
        _lastPositionUpdate = now;
        emit(state.copyWith(position: pos));
      }
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });

    _playerStateSub = _audioService.playerStateStream.listen((jaState) {
      final processingState = jaState.processingState;
      final isPlaying = jaState.playing;

      switch (processingState) {
        case ja.ProcessingState.idle:
          emit(state.copyWith(status: PlayerStatus.idle));
        case ja.ProcessingState.loading:
        case ja.ProcessingState.buffering:
          emit(state.copyWith(status: PlayerStatus.buffering));
        case ja.ProcessingState.ready:
          emit(
            state.copyWith(
              status: isPlaying ? PlayerStatus.playing : PlayerStatus.paused,
            ),
          );
        case ja.ProcessingState.completed:
          emit(state.copyWith(status: PlayerStatus.completed));
          if (_queue.hasNext && isPlaying) {
            next();
          }
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? queue, int? index}) async {
    if (queue != null && queue.isNotEmpty) {
      final startIndex = index ?? queue.indexWhere((t) => t.id == track.id);
      _queue.setQueue(queue, startIndex: startIndex >= 0 ? startIndex : 0);
    } else if (_queue.isEmpty || !_queue.tracks.any((t) => t.id == track.id)) {
      _queue.setQueue([track], startIndex: 0);
    } else if (index != null) {
      _queue.jumpToIndex(index);
    }

    await _playCurrentQueueTrack();
  }

  Future<void> next() async {
    final nextTrack = _queue.next();
    if (nextTrack != null) {
      await _playCurrentQueueTrack();
    } else {
      await _audioService.stop();
      _emitQueueState(status: PlayerStatus.completed);
    }
  }

  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevTrack = _queue.previous();
    if (prevTrack != null) {
      await _playCurrentQueueTrack();
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    final track = _queue.jumpToIndex(index);
    if (track != null) {
      await _playCurrentQueueTrack();
    }
  }

  Future<void> _playCurrentQueueTrack() async {
    final track = _queue.currentTrack;
    if (track == null) return;

    await _audioService.stop();

    _emitQueueState(status: PlayerStatus.resolving, error: null);

    try {
      final resolved = await _resolver.resolveTrack(track);

      bool isLoaded = false;
      while (!isLoaded) {
        try {
          final audioSource = _audioService.createAudioSource(
            track: resolved.track,
            stream: resolved.currentStream,
          );
          await _audioService.setAudioSource(audioSource);
          isLoaded = true;
        } catch (e) {
          if (resolved.hasMoreCandidates) {
            resolved.nextCandidate();
          } else {
            rethrow;
          }
        }
      }

      await _audioService.play();
    } catch (e) {
      _emitQueueState(status: PlayerStatus.error, error: e);
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _audioService.pause();
    } else if (state.status == PlayerStatus.paused ||
        state.status == PlayerStatus.completed) {
      await _audioService.play();
    }
  }

  Future<void> play() async => _audioService.play();

  Future<void> pause() async => _audioService.pause();

  Future<void> seek(Duration position) async => _audioService.seek(position);

  void toggleShuffle() {
    _queue.toggleShuffle();
    _emitQueueState();
  }

  void cycleRepeatMode() {
    _queue.cycleRepeatMode();
    _emitQueueState();
  }

  void addToQueue(Track track) {
    _queue.add(track);
    _emitQueueState();
  }

  void insertNext(Track track) {
    _queue.insertNext(track);
    _emitQueueState();
  }

  void removeFromQueue(int index) {
    _queue.removeAt(index);
    _emitQueueState();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _queue.reorder(oldIndex, newIndex);
    _emitQueueState();
  }

  void _emitQueueState({PlayerStatus? status, Object? error}) {
    emit(
      state.copyWith(
        status: status,
        currentTrack: _queue.currentTrack,
        queue: _queue.tracks,
        currentIndex: _queue.currentIndex,
        isShuffled: _queue.isShuffled,
        repeatMode: _queue.repeatMode,
        error: error,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    await _audioService.dispose();
    return super.close();
  }
}
