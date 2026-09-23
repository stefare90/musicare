import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class AudioStreamResolver {
  final AudioSourcePluginEngine _engine;

  AudioStreamResolver(this._engine);

  Future<PlaybackCandidates> resolveTrack(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final playback = await _engine.resolveTrack(track, quality: quality);

    if (playback.candidates.isEmpty) {
      throw const StreamResolutionException('No playable stream candidates');
    }

    return PlaybackCandidates.fromResolvedPlayback(playback);
  }

  Future<AudioStreamResponse> resolveCandidateStream(
    String candidateId, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    return _engine.resolveStream(candidateId, quality: quality);
  }
}
