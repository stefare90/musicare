import 'dart:async';
import 'dart:collection';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/listening/data/services/listen_sink.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';

class ListeningTracker {
  ListeningTracker({required this._playback, required List<ListenSink> sinks})
    : _sinks = List.unmodifiable(sinks);

  void start() {
    _subscription ??= _playback.listen(_onPlayback);
  }

  /// A position jump larger than this is a seek, not elapsed playback.
  static const Duration seekThreshold = Duration(seconds: 2);

  /// Below this, a pause is buffering or a track change, not "away and back".
  static const Duration resumeAfterPause = Duration(seconds: 5);

  /// Half the track, never more than four minutes.
  static const Duration listenWindow = Duration(minutes: 4);

  /// Shorter tracks never count as a full listen.
  static const Duration minimumTrackLength = Duration(seconds: 30);

  static const int _maxRemembered = 256;

  final Stream<PlaybackData> _playback;
  final List<ListenSink> _sinks;
  final LinkedHashSet<String> _sent = LinkedHashSet<String>();
  StreamSubscription<PlaybackData>? _subscription;

  Track? _track;
  DateTime? _startedAt;
  Duration _played = Duration.zero;
  Duration? _lastPosition;
  bool _everPlayed = false;
  bool _playingNowSent = false;
  DateTime? _playingNowKey;
  DateTime? _pausedAt;

  DateTime get _now => clock.now().toUtc();

  void _onPlayback(PlaybackData data) {
    final track = data.currentTrack;
    if (track == null) {
      _reset();
      return;
    }

    if (_track?.id != track.id || _isRestart(data)) {
      _begin(track, data.position);
      return;
    }

    final now = _now;
    if (!data.isPlaying) {
      _lastPosition = null;
      _pausedAt ??= now;
      return;
    }

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null && now.difference(pausedAt) > resumeAfterPause) {
      _playingNowSent = false;
      _playingNowKey = now;
    }

    _accumulate(data);
    _maybeEmitPlayingNow(track, data);
    _maybeEmitSingle(track, data);
  }

  void _accumulate(PlaybackData data) {
    final last = _lastPosition;
    if (last != null) {
      final delta = data.position - last;
      if (delta > Duration.zero && delta <= seekThreshold) _played += delta;
    }
    _lastPosition = data.position;
    if (data.position > Duration.zero) _everPlayed = true;
  }

  void _maybeEmitPlayingNow(Track track, PlaybackData data) {
    if (_playingNowSent || data.position == Duration.zero) return;
    _playingNowSent = true;
    _emit(
      ListenEvent(kind: ListenKind.playingNow, track: track),
      _playingNowKey ?? _startedAt!,
    );
  }

  void _maybeEmitSingle(Track track, PlaybackData data) {
    final startedAt = _startedAt;
    if (startedAt == null) return;

    final duration = _durationOf(track, data);
    if (duration != null && duration < minimumTrackLength) return;
    final window = duration == null ? listenWindow : _threshold(duration);
    if (_played < window) return;

    _emit(
      ListenEvent(kind: ListenKind.single, track: track, listenedAt: startedAt),
      startedAt,
    );
  }

  static Duration _threshold(Duration duration) {
    final half = duration ~/ 2;
    return half < listenWindow ? half : listenWindow;
  }

  static Duration? _durationOf(Track track, PlaybackData data) {
    if (track.durationMs > 0) return Duration(milliseconds: track.durationMs);
    if (data.duration > Duration.zero) return data.duration;
    return null;
  }

  void _emit(ListenEvent event, DateTime instant) {
    final key =
        '${event.kind.toJson()}|${event.track.id}|'
        '${instant.millisecondsSinceEpoch}';
    if (!_sent.add(key)) return;
    if (_sent.length > _maxRemembered) _sent.remove(_sent.first);

    for (final sink in _sinks) {
      unawaited(_deliver(sink, event));
    }
  }

  Future<void> _deliver(ListenSink sink, ListenEvent event) async {
    try {
      await sink.submit(event);
    } catch (error) {
      debugPrint('listening: sink failed ($error)');
    }
  }

  bool _isRestart(PlaybackData data) =>
      _track != null &&
      _everPlayed &&
      data.processingState == PlaybackProcessingState.loading &&
      data.position == Duration.zero;

  void _begin(Track track, Duration position) {
    _track = track;
    _startedAt = _now;
    _played = Duration.zero;
    _lastPosition = position == Duration.zero ? Duration.zero : null;
    _everPlayed = false;
    _playingNowSent = false;
    _playingNowKey = null;
    _pausedAt = null;
  }

  void _reset() {
    _track = null;
    _startedAt = null;
    _played = Duration.zero;
    _lastPosition = null;
    _everPlayed = false;
    _playingNowSent = false;
    _playingNowKey = null;
    _pausedAt = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
