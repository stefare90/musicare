import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class AudioPlayerDriver {
  final ja.AudioPlayer _player;

  AudioPlayerDriver({ja.AudioPlayer? player})
    : _player = player ?? ja.AudioPlayer();

  static Future<void> initBackground() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.musicare.audio',
      androidNotificationChannelName: 'MusicAre Playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    );
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get isPlayingStream => _player.playingStream;

  Stream<PlaybackProcessingState> get processingStateStream =>
      _player.processingStateStream.map(_mapProcessingState);

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  PlaybackProcessingState get processingState =>
      _mapProcessingState(_player.processingState);

  PlaybackProcessingState _mapProcessingState(ja.ProcessingState state) {
    switch (state) {
      case ja.ProcessingState.idle:
        return PlaybackProcessingState.idle;
      case ja.ProcessingState.loading:
        return PlaybackProcessingState.loading;
      case ja.ProcessingState.buffering:
        return PlaybackProcessingState.buffering;
      case ja.ProcessingState.ready:
        return PlaybackProcessingState.ready;
      case ja.ProcessingState.completed:
        return PlaybackProcessingState.completed;
    }
  }

  Future<void> loadStream({
    required Track track,
    required AudioStreamResponse stream,
  }) async {
    final mediaItem = MediaItem(
      id: track.id,
      album: track.album.name,
      title: track.name,
      artist: track.artists.map((a) => a.name).join(', '),
      duration: track.durationMs > 0
          ? Duration(milliseconds: track.durationMs)
          : null,
      artUri: track.album.images.isNotEmpty
          ? Uri.tryParse(track.album.images.first.url)
          : null,
    );

    final audioSource = ja.AudioSource.uri(
      Uri.parse(stream.url),
      headers: stream.headers.isNotEmpty ? stream.headers : null,
      tag: mediaItem,
    );

    await _player.setAudioSource(audioSource);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
