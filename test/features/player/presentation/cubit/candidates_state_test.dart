import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/presentation/cubit/candidates_state.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

void main() {
  group('CandidatesState Model Unit Tests', () {
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
    );

    test('fromPlaybackCandidates maps domain model accurately', () {
      const domain = PlaybackCandidates(
        candidates: [candidate1, candidate2],
        activeStream: stream1,
        activeCandidateId: 'c2',
      );

      final state = CandidatesState.fromPlaybackCandidates(domain);

      expect(state.count, equals(2));
      expect(state.activeCandidateId, equals('c2'));
      expect(state.activeStream, equals(stream1));
      expect(state.activeCandidate, equals(candidate2));
      expect(state.hasAlternatives, isTrue);
      expect(state.isFallback, isTrue);
    });

    test('value equality is supported', () {
      const s1 = CandidatesState(
        candidates: [candidate1],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );
      const s2 = CandidatesState(
        candidates: [candidate1],
        activeStream: stream1,
        activeCandidateId: 'c1',
      );
      const s3 = CandidatesState(
        candidates: [candidate2],
        activeStream: stream1,
        activeCandidateId: 'c2',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}
