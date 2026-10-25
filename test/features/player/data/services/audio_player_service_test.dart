import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class MockAudioPlayerDriver extends Mock implements AudioPlayerDriver {}

class MockAudioStreamResolver extends Mock implements AudioStreamResolver {}

Track createTestTrack(String id, String name) {
  return Track(
    id: id,
    name: name,
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    ),
    durationMs: 180000,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(createTestTrack('fb_id', 'fb_name'));
    registerFallbackValue(
      const AudioStreamResponse(
        url: 'https://fallback.example.com',
        quality: AudioQuality.high,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioQuality.high);
  });

  group('AudioPlayerService Orchestrator Unit Tests', () {
    late MockAudioPlayerDriver mockDriver;
    late MockAudioStreamResolver mockResolver;
    late AudioPlayerService service;

    late StreamController<PlaybackProcessingState> processingController;
    late StreamController<bool> playingController;
    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;

    final track1 = createTestTrack('1', 'Song 1');
    final track2 = createTestTrack('2', 'Song 2');

    const candidateTrack1 = CandidateTrack(
      id: 'c1',
      title: 'Song 1 (Official)',
    );
    const candidateTrack2 = CandidateTrack(id: 'c2', title: 'Song 1 (Live)');

    const candidate1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/audio.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );

    const candidate2 = AudioStreamResponse(
      url: 'https://cdn2.example.com/audio2.m4a',
      quality: AudioQuality.medium,
      bitrate: 128000,
    );

    setUp(() {
      mockDriver = MockAudioPlayerDriver();
      mockResolver = MockAudioStreamResolver();

      processingController =
          StreamController<PlaybackProcessingState>.broadcast();
      playingController = StreamController<bool>.broadcast();
      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();

      when(
        () => mockDriver.processingStateStream,
      ).thenAnswer((_) => processingController.stream);
      when(
        () => mockDriver.isPlayingStream,
      ).thenAnswer((_) => playingController.stream);
      when(
        () => mockDriver.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        () => mockDriver.durationStream,
      ).thenAnswer((_) => durationController.stream);

      when(() => mockDriver.isPlaying).thenReturn(false);
      when(() => mockDriver.position).thenReturn(Duration.zero);
      when(() => mockDriver.duration).thenReturn(Duration.zero);
      when(
        () => mockDriver.processingState,
      ).thenReturn(PlaybackProcessingState.idle);

      when(
        () => mockDriver.loadStream(
          track: any(named: 'track'),
          stream: any(named: 'stream'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockDriver.play()).thenAnswer((_) async {});
      when(() => mockDriver.pause()).thenAnswer((_) async {});
      when(() => mockDriver.stop()).thenAnswer((_) async {});
      when(() => mockDriver.seek(any())).thenAnswer((_) async {});
      when(() => mockDriver.dispose()).thenAnswer((_) async {});

      when(() => mockResolver.resolveTrack(any())).thenAnswer(
        (_) async => const PlaybackCandidates(
          candidates: [candidateTrack1],
          activeStream: candidate1,
          activeCandidateId: 'c1',
        ),
      );
      when(
        () => mockResolver.resolveCandidateStream(
          any(),
          quality: any(named: 'quality'),
        ),
      ).thenAnswer((_) async => candidate2);

      service = AudioPlayerService(driver: mockDriver, resolver: mockResolver);
    });

    tearDown(() async {
      await processingController.close();
      await playingController.close();
      await positionController.close();
      await durationController.close();
      await service.dispose();
    });

    test('playTrack sets a single track queue and starts playback', () async {
      await service.playTrack(track1);

      expect(service.playbackData.currentTrack, equals(track1));
      expect(service.playbackData.queue.length, equals(1));
      expect(service.playbackData.candidates.count, equals(1));
      verify(() => mockResolver.resolveTrack(track1)).called(1);
      verify(() => mockDriver.play()).called(1);
    });

    test('playQueue initializes queue at index and starts playback', () async {
      await service.playQueue([track1, track2], index: 1);

      expect(service.playbackData.currentTrack, equals(track2));
      expect(service.playbackData.queue.length, equals(2));
      expect(service.playbackData.queue.currentIndex, equals(1));
      verify(() => mockDriver.play()).called(1);
    });

    test(
      'playTrack retries candidate #2 if candidate #1 fails during loadStream',
      () async {
        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => const PlaybackCandidates(
            candidates: [candidateTrack1, candidateTrack2],
            activeStream: candidate1,
            activeCandidateId: 'c1',
          ),
        );
        when(
          () => mockResolver.resolveCandidateStream(
            'c2',
            quality: any(named: 'quality'),
          ),
        ).thenAnswer((_) async => candidate2);

        var attempts = 0;
        when(
          () => mockDriver.loadStream(
            track: track1,
            stream: any(named: 'stream'),
          ),
        ).thenAnswer((invocation) async {
          attempts++;
          final stream =
              invocation.namedArguments[const Symbol('stream')]
                  as AudioStreamResponse;
          if (stream.url == candidate1.url) {
            throw Exception('CDN 403 Forbidden');
          }
        });

        await service.playTrack(track1);

        expect(attempts, equals(2));
        expect(service.playbackData.candidates.activeCandidateId, equals('c2'));
        expect(
          service.playbackData.candidates.activeStream,
          equals(candidate2),
        );
        verify(() => mockDriver.play()).called(1);
      },
    );

    test(
      'selectStreamCandidate reloads chosen stream and preserves state',
      () async {
        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => const PlaybackCandidates(
            candidates: [candidateTrack1, candidateTrack2],
            activeStream: candidate1,
            activeCandidateId: 'c1',
          ),
        );
        when(
          () => mockResolver.resolveCandidateStream(
            'c2',
            quality: any(named: 'quality'),
          ),
        ).thenAnswer((_) async => candidate2);

        await service.playTrack(track1);
        expect(service.playbackData.candidates.activeCandidateId, equals('c1'));

        await service.selectStreamCandidate(1);
        expect(service.playbackData.candidates.activeCandidateId, equals('c2'));
        expect(
          service.playbackData.candidates.activeStream,
          equals(candidate2),
        );
      },
    );

    test('next advances queue and plays next track', () async {
      await service.playQueue([track1, track2], index: 0);
      await service.next();

      expect(service.playbackData.currentTrack, equals(track2));
      expect(service.playbackData.queue.currentIndex, equals(1));
      verify(() => mockDriver.play()).called(2);
    });

    test('next at the end of the queue stops playback', () async {
      await service.playQueue([track1], index: 0);
      await service.next();

      expect(service.playbackData.currentTrack, equals(track1));
      expect(service.playbackData.queue.currentIndex, equals(0));
      verify(() => mockDriver.stop()).called(1);
    });

    test('end of the queue pauses where it is, on demand', () async {
      await service.playQueue([track1], index: 0);
      clearInteractions(mockDriver);

      await service.rewindAndPause();

      verify(() => mockDriver.seek(Duration.zero)).called(1);
      verify(() => mockDriver.pause()).called(1);
    });

    test('end of the queue is left to the caller', () async {
      when(() => mockDriver.isPlaying).thenReturn(true);
      await service.playQueue([track1], index: 0);
      clearInteractions(mockDriver);

      processingController.add(PlaybackProcessingState.completed);
      await Future<void>.delayed(Duration.zero);

      // The cubit may still append a radio batch: no pause here.
      verifyNever(() => mockDriver.seek(any()));
      verifyNever(() => mockDriver.pause());
    });

    test('end of the queue does not touch playback when a next exists', () async {
      when(() => mockDriver.isPlaying).thenReturn(true);
      await service.playQueue([track1, track2], index: 0);
      clearInteractions(mockDriver);

      processingController.add(PlaybackProcessingState.completed);
      await Future<void>.delayed(Duration.zero);

      expect(service.playbackData.currentTrack, equals(track2));
      verifyNever(() => mockDriver.pause());
      verifyNever(() => mockDriver.seek(any()));
    });

    test(
      'failed search clears stale candidates from the previous track',
      () async {
        await service.playTrack(track2);
        expect(service.playbackData.candidates.isNotEmpty, isTrue);

        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => throw const StreamResolutionException(
            'No playable stream candidates',
          ),
        );
        await service.playTrack(track1);

        expect(service.playbackData.candidates.isEmpty, isTrue);
        expect(service.playbackData.error, isNotNull);
      },
    );

    test(
      'failed track ends in a terminal state instead of loading forever',
      () async {
        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => throw const StreamResolutionException(
            'No playable stream candidates',
          ),
        );

        await service.playTrack(track1);

        expect(
          service.playbackData.processingState,
          equals(PlaybackProcessingState.idle),
        );
        expect(service.playbackData.error, isNotNull);
      },
    );

    test(
      'after a failed track the next track plays without restarting',
      () async {
        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => throw const StreamResolutionException(
            'No playable stream candidates',
          ),
        );

        await service.playTrack(track1);
        expect(service.playbackData.error, isNotNull);

        await service.playTrack(track2);

        verify(() => mockResolver.resolveTrack(track2)).called(1);
        verify(() => mockDriver.play()).called(1);
        expect(service.playbackData.currentTrack, equals(track2));
        expect(service.playbackData.error, isNull);
      },
    );

    test('failed candidate switch ends in a terminal state', () async {
      when(() => mockResolver.resolveTrack(track1)).thenAnswer(
        (_) async => const PlaybackCandidates(
          candidates: [candidateTrack1, candidateTrack2],
          activeStream: candidate1,
          activeCandidateId: 'c1',
        ),
      );
      when(
        () => mockResolver.resolveCandidateStream(
          'c2',
          quality: any(named: 'quality'),
        ),
      ).thenAnswer((_) async => throw Exception('CDN 403 Forbidden'));

      await service.playTrack(track1);
      await service.selectStreamCandidate(1);

      expect(
        service.playbackData.processingState,
        equals(PlaybackProcessingState.idle),
      );
      expect(service.playbackData.error, isNotNull);
    });

    test(
      'play after a failed track retries it instead of resuming stale audio',
      () async {
        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => throw const StreamResolutionException(
            'No playable stream candidates',
          ),
        );

        await service.playTrack(track2);
        await service.playTrack(track1);
        await service.play();

        verify(() => mockResolver.resolveTrack(track1)).called(2);
        verify(() => mockDriver.play()).called(1);
      },
    );

    test('play resumes the driver when the current track is loaded', () async {
      await service.playTrack(track1);
      await service.play();

      verify(() => mockDriver.play()).called(2);
    });

    test(
      'queue mutation methods successfully update the playbackData',
      () async {
        await service.playTrack(track1);

        service.addToQueue(track2);
        expect(service.playbackData.queue.length, equals(2));
        expect(service.playbackData.queue.tracks.last, equals(track2));

        service.toggleShuffle();
        expect(service.playbackData.queue.isShuffled, isTrue);

        service.cycleRepeatMode();
        expect(
          service.playbackData.queue.repeatMode,
          equals(PlaybackRepeatMode.all),
        );

        service.removeFromQueue(0);
        expect(service.playbackData.queue.length, equals(1));
      },
    );

    test(
      'a track that cannot be resolved skips to the next one after failing once',
      () async {
        final broken = createTestTrack('broken', 'Broken');
        final good = createTestTrack('good', 'Good');
        when(() => mockResolver.resolveTrack(broken)).thenAnswer(
          (_) async => throw const StreamResolutionException(
            'No playable stream candidates',
          ),
        );

        final failures = <Object>[];
        Object? lastError;
        final subscription = service.playbackDataStream.listen((data) {
          final error = data.error;
          if (error != null && !identical(error, lastError)) {
            failures.add(error);
          }
          lastError = error;
        });

        await service.playQueue([broken, good]);
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(service.playbackData.currentTrack, equals(good));
        expect(service.playbackData.queue.currentIndex, equals(1));
        expect(service.playbackData.error, isNull);
        expect(failures, hasLength(1));
        expect(failures.single, isA<StreamResolutionException>());
        verify(() => mockResolver.resolveTrack(broken)).called(1);
        verify(() => mockResolver.resolveTrack(good)).called(1);
        verify(() => mockDriver.play()).called(1);
      },
    );

    test('a missing stream on the last candidate also skips', () async {
      when(() => mockResolver.resolveTrack(track1)).thenAnswer(
        (_) async => const PlaybackCandidates(
          candidates: [candidateTrack1],
          activeCandidateId: 'c1',
        ),
      );
      when(
        () => mockResolver.resolveCandidateStream(
          'c1',
          quality: any(named: 'quality'),
        ),
      ).thenAnswer(
        (_) async => throw const AudioNotFoundException('gone'),
      );

      await service.playQueue([track1, track2]);

      expect(service.playbackData.currentTrack, equals(track2));
      expect(service.playbackData.error, isNull);
      verify(() => mockDriver.play()).called(1);
    });

    test('all tracks failing stops the chain even with repeat-all', () async {
      final first = createTestTrack('first', 'First');
      final second = createTestTrack('second', 'Second');
      when(() => mockResolver.resolveTrack(any())).thenAnswer(
        (_) async => throw const StreamResolutionException(
          'No playable stream candidates',
        ),
      );

      service.cycleRepeatMode();
      await service.playQueue([first, second]);

      expect(
        service.playbackData.queue.repeatMode,
        equals(PlaybackRepeatMode.all),
      );
      expect(service.playbackData.error, isA<StreamResolutionException>());
      verify(() => mockResolver.resolveTrack(any())).called(2);
      verifyNever(() => mockDriver.play());
    });

    test('rate-limited resolutions do not skip to the next track', () async {
      final good = createTestTrack('good', 'Good');
      when(() => mockResolver.resolveTrack(track1)).thenAnswer(
        (_) async => throw const AudioRateLimitedException('slow down'),
      );

      await service.playQueue([track1, good]);

      expect(service.playbackData.currentTrack, equals(track1));
      expect(service.playbackData.error, isA<AudioRateLimitedException>());
      verifyNever(() => mockResolver.resolveTrack(good));
      verifyNever(() => mockDriver.play());
    });

    test('transport errors do not skip to the next track', () async {
      final good = createTestTrack('good', 'Good');
      when(() => mockResolver.resolveTrack(track1)).thenAnswer(
        (_) async => throw const AudioTransportException('offline'),
      );

      await service.playQueue([track1, good]);

      expect(service.playbackData.currentTrack, equals(track1));
      expect(service.playbackData.error, isA<AudioTransportException>());
      verifyNever(() => mockResolver.resolveTrack(good));
      verifyNever(() => mockDriver.play());
    });

    test('a successful load resets the consecutive failure counter', () async {
      final broken = createTestTrack('broken', 'Broken');
      final good = createTestTrack('good', 'Good');
      when(() => mockResolver.resolveTrack(broken)).thenAnswer(
        (_) async => throw const StreamResolutionException(
          'No playable stream candidates',
        ),
      );

      service.cycleRepeatMode();
      await service.playQueue([broken, good]);
      expect(service.playbackData.currentTrack, equals(good));

      await service.next();

      expect(service.playbackData.currentTrack, equals(good));
      expect(service.playbackData.error, isNull);
      verify(() => mockResolver.resolveTrack(good)).called(2);
    });

    test('skipping the last broken track stops at the end of the queue', () async {
      final broken = createTestTrack('broken', 'Broken');
      final good = createTestTrack('good', 'Good');
      when(() => mockResolver.resolveTrack(broken)).thenAnswer(
        (_) async => throw const StreamResolutionException(
          'No playable stream candidates',
        ),
      );

      await service.playQueue([broken, good]);
      expect(service.playbackData.currentTrack, equals(good));
      clearInteractions(mockDriver);

      await service.next();

      verify(() => mockDriver.stop()).called(1);
    });
  });
}
