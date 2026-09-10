import 'package:flutter/foundation.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

@immutable
class PlaybackCandidates {
  final List<AudioStreamResponse> streams;
  final int activeIndex;

  const PlaybackCandidates({this.streams = const [], this.activeIndex = 0});

  bool get isEmpty => streams.isEmpty;
  bool get isNotEmpty => streams.isNotEmpty;
  int get count => streams.length;
  bool get hasAlternatives => streams.length > 1;
  bool get isFallback => activeIndex > 0;
  bool get hasNext => activeIndex + 1 < streams.length;

  AudioStreamResponse? get activeStream {
    if (isEmpty || activeIndex < 0 || activeIndex >= streams.length) {
      return null;
    }
    return streams[activeIndex];
  }

  bool get isCurrentStreamExpired {
    final expiresAt = activeStream?.expiresAt;
    if (expiresAt == null) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expiryMs = expiresAt < 10000000000 ? expiresAt * 1000 : expiresAt;
    return nowMs >= expiryMs;
  }

  PlaybackCandidates select(int index) {
    if (index >= 0 && index < streams.length) {
      return PlaybackCandidates(streams: streams, activeIndex: index);
    }
    return this;
  }

  PlaybackCandidates next() {
    if (hasNext) {
      return PlaybackCandidates(streams: streams, activeIndex: activeIndex + 1);
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackCandidates &&
          runtimeType == other.runtimeType &&
          activeIndex == other.activeIndex &&
          listEquals(streams, other.streams);

  @override
  int get hashCode => Object.hash(activeIndex, Object.hashAll(streams));
}
