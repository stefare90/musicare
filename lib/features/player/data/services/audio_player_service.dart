import 'dart:async';
import 'dart:math';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/models/playback_pending.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';

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
  String? _loadedTrackId;
  DateTime _lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _maxFetchAttempts = 4;

  PendingLoader? _pendingLoader;
  Future<bool>? _activeFetch;
  bool _pullRunning = false;
  int _pendingGeneration = 0;

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

  Future<void> playQueue(
    List<Track> queue, {
    int index = 0,
    PendingSource? pending,
  }) async {
    if (queue.isEmpty) return;

    final validIndex = (index >= 0 && index < queue.length) ? index : 0;
    _pendingGeneration++;
    final source = (pending != null && !pending.isComplete) ? pending : null;
    _pendingLoader = source?.loader;
    _updateData(
      _playbackData.copyWith(
        queue: _playbackData.queue.setQueue(queue, startIndex: validIndex),
        pending: source == null
            ? const PlaybackPending.empty()
            : PlaybackPending.fromSource(source),
      ),
    );

    _pull();
    await _playCurrentQueueTrack();
  }

  Future<void> next() async {
    final nextFlight = _activeFetch;
    if (nextFlight != null &&
        _playbackData.queue.currentIndex + 1 >= _playbackData.queue.length) {
      await nextFlight;
    }
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

  void _pull() {
    unawaited(_pullLoop());
  }

  Future<void> _pullLoop() async {
    if (_pullRunning) {
      return;
    }
    _pullRunning = true;
    try {
      while (!_playbackData.pending.isEmpty) {
        if (!await _fetchOnePage()) {
          break;
        }
      }
    } finally {
      _pullRunning = false;
    }
  }

  Future<bool> _fetchOnePage() {
    final running = _activeFetch;
    if (running != null) {
      return running;
    }
    final loader = _pendingLoader;
    final live = _playbackData.pending;
    if (loader == null || live.isEmpty) return Future.value(false);
    final generation = _pendingGeneration;
    final offset = live.nextOffset;
    _updateData(_playbackData.copyWith(pending: live.started()));
    final flight = _runFetch(loader, offset, generation);
    _activeFetch = flight;
    flight.whenComplete(() {
      if (identical(_activeFetch, flight)) _activeFetch = null;
    });
    return flight;
  }

  Future<bool> _runFetch(
    PendingLoader loader,
    int offset,
    int generation,
  ) async {
    for (var i = 0; i < _maxFetchAttempts; i++) {
      late final PaginatedResult<Track> page;
      try {
        page = await loader(offset);
      } catch (e) {
        if (generation != _pendingGeneration) {
          return true;
        }
        if (i == _maxFetchAttempts - 1) {
          _updateData(
            _playbackData.copyWith(
              pending: _playbackData.pending.failed(
                PendingLoadException(e),
              ),
            ),
          );
          return false;
        }
        continue;
      }
      if (generation != _pendingGeneration) {
        return true;
      }
      if (page.items.isEmpty) {
        _pendingLoader = null;
        _updateData(
          _playbackData.copyWith(pending: const PlaybackPending.empty()),
        );
        return true;
      }
      _updateData(
        _playbackData.copyWith(
          queue: _queueWithArrivals(_playbackData.queue, page.items),
          pending: _playbackData.pending.advancedBy(
            loaded: page.items.length,
            total: page.total,
          ),
        ),
      );
      return true;
    }
    return false;
  }

  PlaybackQueue _queueWithArrivals(
    PlaybackQueue queue,
    List<Track> arrivals,
  ) {
    if (arrivals.isEmpty) return queue;
    final original = List<Track>.from(queue.originalTracks)..addAll(arrivals);
    final List<Track> tracks;
    if (!queue.isShuffled) {
      tracks = List<Track>.from(queue.tracks)..addAll(arrivals);
    } else {
      final grown = List<Track>.from(queue.tracks);
      final random = Random();
      for (final track in arrivals) {
        final slot =
            queue.currentIndex +
            1 +
            random.nextInt(grown.length - queue.currentIndex);
        grown.insert(slot, track);
      }
      tracks = grown;
    }
    return queue.copyWith(
      tracks: List.unmodifiable(tracks),
      originalTracks: List.unmodifiable(original),
    );
  }

  Future<void> retryPendingLoad() async {
    if (_pendingLoader == null) return;
    _pull();
  }

  Future<void> selectStreamCandidate(int candidateIndex) async {
    final track = _playbackData.currentTrack;
    final candidates = _playbackData.candidates;
    if (track == null ||
        candidateIndex < 0 ||
        candidateIndex >= candidates.candidates.length ||
        candidates.candidates[candidateIndex].id ==
            candidates.activeCandidateId) {
      return;
    }

    final currentPos = _driver.position;
    final wasPlaying = _driver.isPlaying;

    var updatedCandidates = candidates.select(candidateIndex);
    _updateData(
      PlaybackData.loading(
        _playbackData.copyWith(candidates: updatedCandidates),
      ),
    );

    try {
      final stream = await _resolver.resolveCandidateStream(
        updatedCandidates.activeCandidateId!,
      );
      updatedCandidates = updatedCandidates.attachStream(stream);

      _updateData(_playbackData.copyWith(candidates: updatedCandidates));

      await _driver.loadStream(track: track, stream: stream);
      _loadedTrackId = track.id;

      if (currentPos > Duration.zero) {
        await _driver.seek(currentPos);
      }
      if (wasPlaying) {
        await _driver.play();
      }
    } catch (e) {
      _updateData(PlaybackData.failure(_playbackData, e));
    }
  }

  Future<void> _playCurrentQueueTrack() async {
    final track = _playbackData.currentTrack;
    if (track == null) return;

    final sessionId = ++_sessionCounter;

    if (_playbackData.processingState != PlaybackProcessingState.completed) {
      await _driver.pause();
    }
    _updateData(PlaybackData.loading(_playbackData));

    PlaybackCandidates resolvedCandidates;
    try {
      resolvedCandidates = await _resolver.resolveTrack(track);
    } catch (e) {
      if (sessionId != _sessionCounter) return;
      _updateData(
        PlaybackData.failure(
          _playbackData.copyWith(candidates: const PlaybackCandidates()),
          e,
        ),
      );
      return;
    }
    if (sessionId != _sessionCounter) return;

    _updateData(_playbackData.copyWith(candidates: resolvedCandidates));

    try {
      bool isLoaded = false;
      while (!isLoaded) {
        try {
          if (resolvedCandidates.needsStreamResolution) {
            final stream = await _resolver.resolveCandidateStream(
              resolvedCandidates.activeCandidateId!,
            );
            resolvedCandidates = resolvedCandidates.attachStream(stream);
            _updateData(_playbackData.copyWith(candidates: resolvedCandidates));
          }

          final stream = resolvedCandidates.activeStream;
          if (stream == null) {
            throw const StreamResolutionException('No stream available');
          }
          await _driver.loadStream(track: track, stream: stream);
          _loadedTrackId = track.id;
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
      _updateData(PlaybackData.failure(_playbackData, e));
    }
  }

  Future<void> togglePlayPause() async {
    if (_driver.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    final track = _playbackData.currentTrack;
    if (track != null && _loadedTrackId != track.id) {
      await _playCurrentQueueTrack();
    } else {
      await _driver.play();
    }
  }

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
  void addAllToQueue(List<Track> tracks) => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.addAll(tracks)),
  );
  void insertAllNext(List<Track> tracks) => _updateData(
    _playbackData.copyWith(queue: _playbackData.queue.insertAllNext(tracks)),
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
