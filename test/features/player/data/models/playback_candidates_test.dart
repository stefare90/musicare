import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

void main() {
  group('PlaybackCandidates Model Unit Tests', () {
    const stream1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/1.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );
    const stream2 = AudioStreamResponse(
      url: 'https://cdn2.example.com/2.opus',
      quality: AudioQuality.medium,
      bitrate: 128000,
    );

    test('default constructor returns safe zero-state values', () {
      const candidates = PlaybackCandidates();

      expect(candidates.isEmpty, isTrue);
      expect(candidates.isNotEmpty, isFalse);
      expect(candidates.count, equals(0));
      expect(candidates.hasAlternatives, isFalse);
      expect(candidates.isFallback, isFalse);
      expect(candidates.activeStream, isNull);
      expect(candidates.isCurrentStreamExpired, isFalse);
    });

    test('provides activeStream and calculates flags correctly', () {
      const candidates = PlaybackCandidates(
        streams: [stream1, stream2],
        activeIndex: 0,
      );

      expect(candidates.count, equals(2));
      expect(candidates.hasAlternatives, isTrue);
      expect(candidates.isFallback, isFalse);
      expect(candidates.activeStream, equals(stream1));
    });

    test('select updates activeIndex with bounds validation', () {
      const candidates = PlaybackCandidates(
        streams: [stream1, stream2],
        activeIndex: 0,
      );

      final updated = candidates.select(1);
      expect(updated.activeIndex, equals(1));
      expect(updated.activeStream, equals(stream2));
      expect(updated.isFallback, isTrue);

      final invalid = candidates.select(5);
      expect(invalid.activeIndex, equals(0));
    });

    test('next advances to subsequent candidate when available', () {
      const candidates = PlaybackCandidates(
        streams: [stream1, stream2],
        activeIndex: 0,
      );

      final nextCandidates = candidates.next();
      expect(nextCandidates.activeIndex, equals(1));
      expect(nextCandidates.activeStream, equals(stream2));

      final endCandidates = nextCandidates.next();
      expect(endCandidates.activeIndex, equals(1));
    });

    test('isCurrentStreamExpired evaluates timestamp comparison correctly', () {
      final pastStream = AudioStreamResponse(
        url: 'https://cdn.example.com/expired.m4a',
        quality: AudioQuality.high,
        expiresAt: DateTime.now().millisecondsSinceEpoch - 10000,
      );
      final validStream = AudioStreamResponse(
        url: 'https://cdn.example.com/valid.m4a',
        quality: AudioQuality.high,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 1000000,
      );

      final expiredCandidates = PlaybackCandidates(streams: [pastStream]);
      expect(expiredCandidates.isCurrentStreamExpired, isTrue);

      final validCandidates = PlaybackCandidates(streams: [validStream]);
      expect(validCandidates.isCurrentStreamExpired, isFalse);
    });

    test('value equality is supported', () {
      const c1 = PlaybackCandidates(streams: [stream1], activeIndex: 0);
      const c2 = PlaybackCandidates(streams: [stream1], activeIndex: 0);
      const c3 = PlaybackCandidates(streams: [stream2], activeIndex: 0);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}
