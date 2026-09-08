import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class AudioStreamResolver {
  final AudioSourcePluginEngine _engine;

  AudioStreamResolver(this._engine);

  Future<ResolvedPlaybackTrack> resolveTrack(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final streams = await _engine.resolveStream(track, quality: quality);
    if (streams.isEmpty) {
      throw StreamResolutionException('No playable stream');
    }

    return ResolvedPlaybackTrack(track: track, candidates: streams);
  }
}
