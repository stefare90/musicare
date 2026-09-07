import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerCubit extends SafeCubit<PlayerState> {
  final AudioPlayerService _audioService;
  final AudioStreamResolver _resolver;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;

  PlayerCubit({
    required AudioPlayerService audioService,
    required AudioStreamResolver resolver,
  }) : _audioService = audioService,
       _resolver = resolver,
       super(const PlayerState()) {
    _initAudioStreams();
  }

  void _initAudioStreams() {
    _positionSub = _audioService.positionStream.listen((pos) {
      emit(state.copyWith(position: pos));
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });

    _playerStateSub = _audioService.playerStateStream.listen((jaState) {
      final processingState = jaState.processingState;
      final isPlaying = jaState.playing;

      if (state.status == PlayerStatus.resolving) {
        return;
      }

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
      }
    });
  }

  /// Resolves track stream URL and starts playback with automatic candidate fallback.
  Future<void> playTrack(Track track) async {
    emit(
      state.copyWith(
        status: PlayerStatus.resolving,
        currentTrack: track,
        error: null,
      ),
    );

    try {
      final resolved = await _resolver.resolveTrack(track);

      // Attempt loading stream candidates with fallback on network/CDN failure
      bool isLoaded = false;
      while (!isLoaded) {
        try {
          final audioSource = _resolver.createAudioSource(resolved);
          await _audioService.setAudioSource(audioSource);
          isLoaded = true;
        } catch (e) {
          if (resolved.hasMoreCandidates) {
            resolved.nextCandidate();
          } else {
            resolved.resetCandidate();
            rethrow;
          }
        }
      }

      await _audioService.play();
    } catch (e) {
      emit(state.copyWith(status: PlayerStatus.error, error: e));
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

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    await _audioService.dispose();
    return super.close();
  }
}
