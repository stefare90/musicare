import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

void main() {
  group('ResolvedPlaybackTrack Model Unit Tests', () {
    final testTrack = Track(
      id: 't1',
      name: 'Come Together',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      ),
      durationMs: 259000,
    );

    const candidate1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/stream1.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );

    const candidate2 = AudioStreamResponse(
      url: 'https://cdn2.example.com/stream2.m4a',
      quality: AudioQuality.high,
      bitrate: 128000,
    );

    test('throws AssertionError if candidates list is empty', () {
      expect(
        () => ResolvedPlaybackTrack(track: testTrack, candidates: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('initializes with primary candidate at index 0', () {
      final playbackTrack = ResolvedPlaybackTrack(
        track: testTrack,
        candidates: [candidate1, candidate2],
      );

      expect(playbackTrack.currentCandidateIndex, equals(0));
      expect(playbackTrack.currentStream, equals(candidate1));
      expect(playbackTrack.candidateCount, equals(2));
      expect(playbackTrack.hasMoreCandidates, isTrue);
      expect(playbackTrack.isUsingFallback, isFalse);
    });

    test('nextCandidate advances index and updates isUsingFallback', () {
      final playbackTrack = ResolvedPlaybackTrack(
        track: testTrack,
        candidates: [candidate1, candidate2],
      );

      final didAdvance = playbackTrack.nextCandidate();

      expect(didAdvance, isTrue);
      expect(playbackTrack.currentCandidateIndex, equals(1));
      expect(playbackTrack.currentStream, equals(candidate2));
      expect(playbackTrack.hasMoreCandidates, isFalse);
      expect(playbackTrack.isUsingFallback, isTrue);
    });

    test('nextCandidate returns false and stops at last candidate', () {
      final playbackTrack = ResolvedPlaybackTrack(
        track: testTrack,
        candidates: [candidate1, candidate2],
      );

      playbackTrack.nextCandidate();
      final exceededAdvance = playbackTrack.nextCandidate();

      expect(exceededAdvance, isFalse);
      expect(playbackTrack.currentCandidateIndex, equals(1));
    });

    test('resetCandidate restores pointer back to index 0', () {
      final playbackTrack = ResolvedPlaybackTrack(
        track: testTrack,
        candidates: [candidate1, candidate2],
      );

      playbackTrack.nextCandidate();
      expect(playbackTrack.isUsingFallback, isTrue);

      playbackTrack.resetCandidate();
      expect(playbackTrack.currentCandidateIndex, equals(0));
      expect(playbackTrack.currentStream, equals(candidate1));
      expect(playbackTrack.isUsingFallback, isFalse);
    });
  });
}
