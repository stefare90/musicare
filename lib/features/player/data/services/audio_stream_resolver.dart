import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class AudioStreamResolver {
  final AudioSourcePluginEngine _engine;

  AudioStreamResolver(this._engine);

  /// Resolves the track by querying the active audio source plugin.
  Future<ResolvedPlaybackTrack> resolveTrack(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    if (!_engine.isRunning) {
      throw PluginNotLoadedException();
    }

    final streams = await _engine.resolveStream(track, quality: quality);
    if (streams.isEmpty) {
      throw StreamResolutionException(
        'No playable stream candidates found for track: "${track.name}"',
      );
    }

    return ResolvedPlaybackTrack(track: track, candidates: streams);
  }

  /// Creates a just_audio AudioSource with required HTTP headers and MediaItem tag.
  AudioSource createAudioSource(ResolvedPlaybackTrack resolvedTrack) {
    final stream = resolvedTrack.currentStream;
    final track = resolvedTrack.track;

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

    return AudioSource.uri(
      Uri.parse(stream.url),
      headers: stream.headers.isNotEmpty ? stream.headers : null,
      tag: mediaItem,
    );
  }
}
