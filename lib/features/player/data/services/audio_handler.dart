import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';

class MusicAreAudioHandler extends BaseAudioHandler {
  final AudioPlayerService _service;
  StreamSubscription<PlaybackData>? _playbackSubscription;
  String? _publishedTrackId;

  MusicAreAudioHandler(this._service) {
    _playbackSubscription = _service.playbackDataStream.listen(_publish);
  }

  void _publish(PlaybackData data) {
    final track = data.currentTrack;
    if (track != null && track.id != _publishedTrackId) {
      _publishedTrackId = track.id;
      mediaItem.add(AudioPlayerDriver.mediaItemFor(track));
    }

    final controls = <MediaControl>[
      if (data.queue.hasPrevious) MediaControl.skipToPrevious,
      if (data.isPlaying) MediaControl.pause else MediaControl.play,
      if (data.queue.hasNext) MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: List<int>.generate(
          controls.length,
          (index) => index,
        ),
        processingState: _mapProcessingState(data.processingState),
        playing: data.isPlaying,
        updatePosition: data.position,
        bufferedPosition: data.position,
        queueIndex: data.queue.isEmpty ? null : data.queue.currentIndex,
      ),
    );
  }

  static AudioProcessingState _mapProcessingState(
    PlaybackProcessingState state,
  ) {
    switch (state) {
      case PlaybackProcessingState.idle:
        return AudioProcessingState.idle;
      case PlaybackProcessingState.loading:
        return AudioProcessingState.loading;
      case PlaybackProcessingState.buffering:
        return AudioProcessingState.buffering;
      case PlaybackProcessingState.ready:
        return AudioProcessingState.ready;
      case PlaybackProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => _service.play();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> seek(Duration position) => _service.seek(position);

  @override
  Future<void> skipToNext() => _service.next();

  @override
  Future<void> skipToPrevious() => _service.previous();

  @override
  Future<void> skipToQueueItem(int index) => _service.skipToIndex(index);

  Future<void> dispose() async {
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
  }
}
