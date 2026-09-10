import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class AudioPlayerService {
  final AudioPlayerDriver _driver;
  final AudioStreamResolver _resolver;

  final StreamController<PlaybackData> _playbackDataController =
      StreamController<PlaybackData>.broadcast();

  PlaybackData _playbackData = const PlaybackData();
  StreamSubscription<bool>? _driverPlayingSub;
  StreamSubscription<PlaybackProcessingState>? _driverProcessingSub;
  StreamSubscription<Duration>? _driverPositionSub;
  StreamSubscription<Duration?>? _driverDurationSub;

  int _sessionCounter = 0;
  DateTime _lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayerService({required this._driver, required this._resolver}) {
    _initDriverListeners();
  }

  Stream<PlaybackData> get playbackDataStream => _playbackDataController.stream;
  PlaybackData get playbackData => _playbackData;

  void _updateData(PlaybackData newData) {
    _playbackData = newData;
    if (!_playbackDataController.isClosed) {
      _playbackDataController.add(_playbackData);
    }
  }

  void _initDriverListeners() {
    _driverPlayingSub = _driver.isPlayingStream.listen((isPlaying) {
      _updateData(_playbackData.copyWith(isPlaying: isPlaying));
    });

    _driverProcessingSub = _driver.processingStateStream.listen((procState) {
      _updateData(_playbackData.copyWith(processingState: procState));
      if (procState == PlaybackProcessingState.completed &&
          _driver.isPlaying &&
          _playbackData.queue.hasNext) {
        next();
      }
    });

    _driverPositionSub = _driver.positionStream.listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastPositionUpdate).inMilliseconds >= 250 ||
          pos == Duration.zero) {
        _lastPositionUpdate = now;
        _updateData(_playbackData.copyWith(position: pos));
      }
    });

    _driverDurationSub = _driver.durationStream.listen((dur) {
      if (dur != null) {
        _updateData(_playbackData.copyWith(duration: dur));
      }
    });
  }

  Future<void> playTrack(Track track) => playQueue([track], index: 0);

  Future<void> playQueue(List<Track> queue, {int index = 0}) async {
    if (queue.isEmpty) return;

    final validIndex = (index >= 0 && index < queue.length) ? index : 0;
    _updateData(
      _playbackData.copyWith(
        queue: _playbackData.queue.setQueue(queue, startIndex: validIndex),
      ),
    );

    await _playCurrentQueueTrack();
  }

  Future<void> next() async {
    final nextQueue = _playbackData.queue.next();
    if (nextQueue != null) {
      _updateData(_playbackData.copyWith(queue: nextQueue));
      await _playCurrentQueueTrack();
    } else {
      await stop();
    }
  }

  Future<void> previous() async {
    if (_driver.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevQueue = _playbackData.queue.previous();
    if (prevQueue != null) {
      _updateData(_playbackData.copyWith(queue: prevQueue));
      await _playCurrentQueueTrack();
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    final jumped = _playbackData.queue.jumpToIndex(index);
    if (jumped != null) {
      _updateData(_playbackData.copyWith(queue: jumped));
      await _playCurrentQueueTrack();
    }
  }

  Future<void> selectStreamCandidate(int candidateIndex) async {
    final track = _playbackData.currentTrack;
    final candidates = _playbackData.candidates;
    if (track == null ||
        candidateIndex < 0 ||
        candidateIndex >= candidates.streams.length ||
        candidateIndex == candidates.activeIndex) {
      return;
    }

    final currentPos = _driver.position;
    final wasPlaying = _driver.isPlaying;

    final updatedCandidates = candidates.select(candidateIndex);
    _updateData(
      _playbackData.copyWith(
        candidates: updatedCandidates,
        processingState: PlaybackProcessingState.loading,
      ),
    );

    try {
      final stream = updatedCandidates.activeStream;
      if (stream != null) {
        await _driver.loadStream(track: track, stream: stream);
      }
      if (currentPos > Duration.zero) {
        await _driver.seek(currentPos);
      }
      if (wasPlaying) {
        await _driver.play();
      }
    } catch (e) {
      _updateData(_playbackData.copyWith(error: e));
    }
  }

  Future<void> _playCurrentQueueTrack() async {
    final track = _playbackData.currentTrack;
    if (track == null) return;

    final sessionId = ++_sessionCounter;

    await _driver.stop();
    _updateData(
      _playbackData.copyWith(
        processingState: PlaybackProcessingState.loading,
        position: Duration.zero,
        duration: Duration.zero,
        error: null,
      ),
    );

    try {
      var resolvedCandidates = await _resolver.resolveTrack(track);
      if (sessionId != _sessionCounter) return;

      _updateData(_playbackData.copyWith(candidates: resolvedCandidates));

      bool isLoaded = false;
      while (!isLoaded) {
        try {
          final stream = resolvedCandidates.activeStream;
          if (stream == null) {
            throw const StreamResolutionException('No stream available');
          }
          await _driver.loadStream(track: track, stream: stream);
          isLoaded = true;
        } catch (e) {
          if (sessionId != _sessionCounter) return;
          if (resolvedCandidates.hasNext) {
            resolvedCandidates = resolvedCandidates.next();
            _updateData(_playbackData.copyWith(candidates: resolvedCandidates));
          } else {
            rethrow;
          }
        }
      }

      if (sessionId != _sessionCounter) return;

      await _driver.play();
    } catch (e) {
      if (sessionId != _sessionCounter) return;
      _updateData(_playbackData.copyWith(error: e));
    }
  }

  Future<void> togglePlayPause() async {
    if (_driver.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() => _driver.play();
  Future<void> pause() => _driver.pause();
  Future<void> stop() => _driver.stop();
  Future<void> seek(Duration position) => _driver.seek(position);

  void toggleShuffle() => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.toggleShuffle()),
  );
  void cycleRepeatMode() => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.cycleRepeatMode()),
  );
  void addToQueue(Track track) => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.add(track)),
  );
  void insertNext(Track track) => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.insertNext(track)),
  );
  void removeFromQueue(int index) => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.removeAt(index)),
  );
  void reorderQueue(int oldIndex, int newIndex) => _updateData(
    _playbackData.copyWith(
      queue: _playbackData.queue.reorder(oldIndex, newIndex),
    ),
  );

  Future<void> dispose() async {
    await _driverPlayingSub?.cancel();
    await _driverProcessingSub?.cancel();
    await _driverPositionSub?.cancel();
    await _driverDurationSub?.cancel();
    await _playbackDataController.close();
    await _driver.dispose();
  }
}
