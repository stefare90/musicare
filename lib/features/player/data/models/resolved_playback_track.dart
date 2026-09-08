import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class ResolvedPlaybackTrack {
  final Track track;
  final List<AudioStreamResponse> candidates;
  int currentCandidateIndex;

  ResolvedPlaybackTrack({
    required this.track,
    required this.candidates,
    this.currentCandidateIndex = 0,
  }) : assert(candidates.isNotEmpty, 'Candidates list cannot be empty');

  AudioStreamResponse get currentStream => candidates[currentCandidateIndex];
  int get candidateCount => candidates.length;
  bool get hasMoreCandidates => currentCandidateIndex + 1 < candidates.length;
  bool get isUsingFallback => currentCandidateIndex > 0;

  bool get isCurrentStreamExpired {
    final expiresAt = currentStream.expiresAt;
    if (expiresAt == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expiryMs = expiresAt < 10000000000 ? expiresAt * 1000 : expiresAt;
    return nowMs >= expiryMs;
  }

  bool nextCandidate() {
    if (hasMoreCandidates) {
      currentCandidateIndex++;
      return true;
    }
    return false;
  }

  void resetCandidate() {
    currentCandidateIndex = 0;
  }
}
