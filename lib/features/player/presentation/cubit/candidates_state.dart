import 'package:flutter/foundation.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

@immutable
class CandidatesState {
  final List<AudioStreamResponse> streams;
  final int activeIndex;
  final bool hasAlternatives;
  final bool isFallback;

  const CandidatesState({
    this.streams = const [],
    this.activeIndex = 0,
    this.hasAlternatives = false,
    this.isFallback = false,
  });

  factory CandidatesState.fromPlaybackCandidates(PlaybackCandidates candidates) {
    return CandidatesState(
      streams: candidates.streams,
      activeIndex: candidates.activeIndex,
      hasAlternatives: candidates.hasAlternatives,
      isFallback: candidates.isFallback,
    );
  }

  bool get isEmpty => streams.isEmpty;
  bool get isNotEmpty => streams.isNotEmpty;
  int get count => streams.length;

  AudioStreamResponse? get activeStream {
    if (isEmpty || activeIndex < 0 || activeIndex >= streams.length) {
      return null;
    }
    return streams[activeIndex];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidatesState &&
          runtimeType == other.runtimeType &&
          activeIndex == other.activeIndex &&
          hasAlternatives == other.hasAlternatives &&
          isFallback == other.isFallback &&
          listEquals(streams, other.streams);

  @override
  int get hashCode => Object.hash(
        activeIndex,
        hasAlternatives,
        isFallback,
        Object.hashAll(streams),
      );
}
