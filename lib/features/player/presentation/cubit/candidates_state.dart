import 'package:flutter/foundation.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

@immutable
class CandidatesState {
  final List<CandidateTrack> candidates;
  final AudioStreamResponse? activeStream;
  final String? activeCandidateId;
  final bool hasAlternatives;
  final bool isFallback;

  const CandidatesState({
    this.candidates = const [],
    this.activeStream,
    this.activeCandidateId,
    this.hasAlternatives = false,
    this.isFallback = false,
  });

  factory CandidatesState.fromPlaybackCandidates(PlaybackCandidates candidates) {
    return CandidatesState(
      candidates: candidates.candidates,
      activeStream: candidates.activeStream,
      activeCandidateId: candidates.activeCandidateId,
      hasAlternatives: candidates.hasAlternatives,
      isFallback: candidates.isFallback,
    );
  }

  bool get isEmpty => candidates.isEmpty;
  bool get isNotEmpty => candidates.isNotEmpty;
  int get count => candidates.length;

  CandidateTrack? get activeCandidate {
    if (activeCandidateId == null) return null;
    return candidates.where((c) => c.id == activeCandidateId).firstOrNull;
  }

  int get activeIndex {
    if (activeCandidateId == null) return -1;
    return candidates.indexWhere((c) => c.id == activeCandidateId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidatesState &&
          runtimeType == other.runtimeType &&
          activeCandidateId == other.activeCandidateId &&
          activeStream == other.activeStream &&
          hasAlternatives == other.hasAlternatives &&
          isFallback == other.isFallback &&
          listEquals(candidates, other.candidates);

  @override
  int get hashCode => Object.hash(
        activeCandidateId,
        activeStream,
        hasAlternatives,
        isFallback,
        Object.hashAll(candidates),
      );
}
