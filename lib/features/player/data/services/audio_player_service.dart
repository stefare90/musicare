import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';

class AudioPlayerService {
  final ja.AudioPlayer _player;

  AudioPlayerService({ja.AudioPlayer? player})
    : _player = player ?? ja.AudioPlayer();

  static Future<void> initBackground() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.musicare.audio',
      androidNotificationChannelName: 'MusicAre Playback',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  }

  ja.AudioPlayer get rawPlayer => _player;

  ja.PlayerState get playerState => _player.playerState;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<ja.PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> setAudioSource(ja.AudioSource source) =>
      _player.setAudioSource(source);

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
