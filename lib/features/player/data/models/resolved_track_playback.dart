import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

/// A track's playable stream together with the candidate list it was chosen from.
///
/// It used to live in the audio host SDK; it is host policy (which candidate to resolve,
/// when to fall back), so the app owns it.
class ResolvedTrackPlayback {
  final AudioStreamResponse? stream;
  final List<CandidateTrack> candidates;
  final String activeCandidateId;

  const ResolvedTrackPlayback({
    required this.stream,
    required this.candidates,
    required this.activeCandidateId,
  });

  @override
  String toString() =>
      'ResolvedTrackPlayback(activeCandidateId: $activeCandidateId, '
      'candidatesCount: ${candidates.length}, stream: $stream)';
}
