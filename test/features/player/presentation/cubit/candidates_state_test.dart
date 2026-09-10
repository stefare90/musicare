import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/presentation/cubit/candidates_state.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

void main() {
  group('CandidatesState Model Unit Tests', () {
    const stream1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/1.m4a',
      quality: AudioQuality.high,
    );
    const stream2 = AudioStreamResponse(
      url: 'https://cdn2.example.com/2.opus',
      quality: AudioQuality.medium,
    );

    test('fromPlaybackCandidates maps domain model accurately', () {
      const domain = PlaybackCandidates(
        streams: [stream1, stream2],
        activeIndex: 1,
      );

      final state = CandidatesState.fromPlaybackCandidates(domain);

      expect(state.count, equals(2));
      expect(state.activeIndex, equals(1));
      expect(state.hasAlternatives, isTrue);
      expect(state.isFallback, isTrue);
      expect(state.activeStream, equals(stream2));
    });

    test('value equality is supported', () {
      const s1 = CandidatesState(streams: [stream1], activeIndex: 0);
      const s2 = CandidatesState(streams: [stream1], activeIndex: 0);
      const s3 = CandidatesState(streams: [stream2], activeIndex: 1);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}
