import 'package:flutter/foundation.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

@immutable
class PlaybackCandidates {
  final List<CandidateTrack> candidates;
  final AudioStreamResponse? activeStream;
  final String? activeCandidateId;

  const PlaybackCandidates({
    this.candidates = const [],
    this.activeStream,
    this.activeCandidateId,
  });

  factory PlaybackCandidates.fromResolvedPlayback(
    ResolvedTrackPlayback playback,
  ) {
    return PlaybackCandidates(
      candidates: playback.candidates,
      activeStream: playback.stream,
      activeCandidateId: playback.activeCandidateId,
    );
  }

  bool get isEmpty => candidates.isEmpty;
  bool get isNotEmpty => candidates.isNotEmpty;
  int get count => candidates.length;
  bool get hasAlternatives => candidates.length > 1;

  int get activeIndex {
    if (activeCandidateId == null) return -1;
    return candidates.indexWhere((c) => c.id == activeCandidateId);
  }

  CandidateTrack? get currentCandidate {
    final idx = activeIndex;
    if (idx >= 0 && idx < candidates.length) {
      return candidates[idx];
    }
    return null;
  }

  bool get isFallback => activeIndex > 0;
  bool get hasNext => activeIndex >= 0 && activeIndex + 1 < candidates.length;

  CandidateTrack? get nextCandidate {
    if (hasNext) {
      return candidates[activeIndex + 1];
    }
    return null;
  }

  bool get isCurrentStreamExpired {
    final expiresAt = activeStream?.expiresAt;
    if (expiresAt == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expiryMs = expiresAt < 10000000000 ? expiresAt * 1000 : expiresAt;
    return nowMs >= expiryMs;
  }

  bool get needsStreamResolution =>
      activeStream == null && activeCandidateId != null;

  PlaybackCandidates select(int index) {
    if (index >= 0 && index < candidates.length) {
      return PlaybackCandidates(
        candidates: candidates,
        activeStream: null,
        activeCandidateId: candidates[index].id,
      );
    }
    return this;
  }

  PlaybackCandidates next() {
    if (hasNext) {
      return PlaybackCandidates(
        candidates: candidates,
        activeStream: null,
        activeCandidateId: candidates[activeIndex + 1].id,
      );
    }
    return this;
  }

  PlaybackCandidates attachStream(AudioStreamResponse stream) {
    return PlaybackCandidates(
      candidates: candidates,
      activeStream: stream,
      activeCandidateId: activeCandidateId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackCandidates &&
          runtimeType == other.runtimeType &&
          activeCandidateId == other.activeCandidateId &&
          activeStream == other.activeStream &&
          listEquals(candidates, other.candidates);

  @override
  int get hashCode =>
      Object.hash(activeCandidateId, activeStream, Object.hashAll(candidates));
}
