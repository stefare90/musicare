import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

/// Encapsulates a track and its resolved audio stream candidates.
///
/// Manages candidate index tracking, fallback navigation, and token expiration checks.
class ResolvedPlaybackTrack {
  final Track track;
  final List<AudioStreamResponse> candidates;
  int currentCandidateIndex;

  ResolvedPlaybackTrack({
    required this.track,
    required this.candidates,
    this.currentCandidateIndex = 0,
  }) : assert(candidates.isNotEmpty, 'Candidates list cannot be empty');

  /// Active stream candidate currently selected for playback.
  AudioStreamResponse get currentStream => candidates[currentCandidateIndex];

  /// Total number of available candidate streams.
  int get candidateCount => candidates.length;

  /// Whether there is at least one fallback candidate available after current.
  bool get hasMoreCandidates => currentCandidateIndex + 1 < candidates.length;

  /// Whether playback is currently using a fallback candidate (index > 0).
  bool get isUsingFallback => currentCandidateIndex > 0;

  /// Checks if the active stream URL has expired based on expiresAt timestamp.
  bool get isCurrentStreamExpired {
    final expiresAt = currentStream.expiresAt;
    if (expiresAt == null) return false;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Handle both second and millisecond timestamp formats
    final expiryMs = expiresAt < 10000000000 ? expiresAt * 1000 : expiresAt;
    return nowMs >= expiryMs;
  }

  /// Advances to the next stream candidate.
  /// Returns true if advanced, or false if already at the last candidate.
  bool nextCandidate() {
    if (hasMoreCandidates) {
      currentCandidateIndex++;
      return true;
    }
    return false;
  }

  /// Resets the candidate pointer back to the primary (highest scored) stream candidate.
  void resetCandidate() {
    currentCandidateIndex = 0;
  }
}
