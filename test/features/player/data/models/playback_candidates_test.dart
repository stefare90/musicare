import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

void main() {
  group('PlaybackCandidates Model Unit Tests', () {
    const candidate1 = CandidateTrack(
      id: 'c1',
      title: 'Song 1 (Official)',
      artist: 'Artist',
      durationMs: 200000,
    );
    const candidate2 = CandidateTrack(
      id: 'c2',
      title: 'Song 1 (Live)',
      artist: 'Artist Live',
      durationMs: 210000,
    );
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
      expect(candidates.activeCandidateId, isNull);
      expect(candidates.currentCandidate, isNull);
      expect(candidates.isCurrentStreamExpired, isFalse);
      expect(candidates.needsStreamResolution, isFalse);
    });

    test('fromResolvedPlayback constructs populated model accurately', () {
      const playback = ResolvedTrackPlayback(
        stream: stream1,
        candidates: [candidate1, candidate2],
        activeCandidateId: 'c1',
      );

      final model = PlaybackCandidates.fromResolvedPlayback(playback);

      expect(model.count, equals(2));
      expect(model.activeCandidateId, equals('c1'));
      expect(model.activeStream, equals(stream1));
      expect(model.currentCandidate, equals(candidate1));
      expect(model.hasAlternatives, isTrue);
      expect(model.isFallback, isFalse);
      expect(model.needsStreamResolution, isFalse);
    });

    test('select updates activeCandidateId and clears stream for JIT resolution', () {
      const candidates = PlaybackCandidates(
        candidates: [candidate1, candidate2],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );

      final selected = candidates.select(1);
      expect(selected.activeCandidateId, equals('c2'));
      expect(selected.activeStream, isNull);
      expect(selected.needsStreamResolution, isTrue);
      expect(selected.isFallback, isTrue);
    });

    test('next advances to subsequent candidate and clears stream for JIT resolution', () {
      const candidates = PlaybackCandidates(
        candidates: [candidate1, candidate2],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );

      expect(candidates.hasNext, isTrue);
      expect(candidates.nextCandidate, equals(candidate2));

      final nextState = candidates.next();
      expect(nextState.activeCandidateId, equals('c2'));
      expect(nextState.activeStream, isNull);
      expect(nextState.needsStreamResolution, isTrue);
      expect(nextState.hasNext, isFalse);
    });

    test('attachStream attaches newly resolved stream to active candidate', () {
      final pending = const PlaybackCandidates(
        candidates: [candidate1, candidate2],
        activeCandidateId: 'c2',
      );

      expect(pending.needsStreamResolution, isTrue);

      final attached = pending.attachStream(stream2);
      expect(attached.activeStream, equals(stream2));
      expect(attached.activeCandidateId, equals('c2'));
      expect(attached.needsStreamResolution, isFalse);
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

      final expiredCandidates = PlaybackCandidates(
        candidates: [candidate1],
        activeStream: pastStream,
        activeCandidateId: 'c1',
      );
      expect(expiredCandidates.isCurrentStreamExpired, isTrue);

      final validCandidates = PlaybackCandidates(
        candidates: [candidate1],
        activeStream: validStream,
        activeCandidateId: 'c1',
      );
      expect(validCandidates.isCurrentStreamExpired, isFalse);
    });

    test('value equality is supported', () {
      const c1 = PlaybackCandidates(
        candidates: [candidate1],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );
      const c2 = PlaybackCandidates(
        candidates: [candidate1],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );
      const c3 = PlaybackCandidates(
        candidates: [candidate2],
        activeStream: stream2,
        activeCandidateId: 'c2',
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}
