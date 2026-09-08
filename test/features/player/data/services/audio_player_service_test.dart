import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/repeat_mode.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

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

    const candidate1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/audio.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
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
        (invocation) async => ResolvedPlaybackTrack(
          track: invocation.positionalArguments[0] as Track,
          candidates: [candidate1],
        ),
      );

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
        const candidate2 = AudioStreamResponse(
          url: 'https://cdn2.example.com/audio2.m4a',
          quality: AudioQuality.high,
          bitrate: 128000,
        );

        when(() => mockResolver.resolveTrack(track1)).thenAnswer(
          (_) async => ResolvedPlaybackTrack(
            track: track1,
            candidates: [candidate1, candidate2],
          ),
        );

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
        verify(() => mockDriver.play()).called(1);
      },
    );

    test('initial state has empty queue and is idle', () {
      expect(service.playbackData.queue.isEmpty, isTrue);
      expect(service.playbackData.isPlaying, isFalse);
      expect(
        service.playbackData.processingState,
        equals(PlaybackProcessingState.idle),
      );
    });

    test('next advances queue and plays next track', () async {
      await service.playQueue([track1, track2], index: 0);

      await service.next();

      expect(service.playbackData.currentTrack, equals(track2));
      expect(service.playbackData.queue.currentIndex, equals(1));
      // 1 from initial playQueue, 1 from next()
      verify(() => mockDriver.play()).called(2);
    });

    test('previous seeks to zero if position > 3 seconds', () async {
      await service.playQueue([track1, track2], index: 1);

      // Simulate playback past 3 seconds
      when(() => mockDriver.position).thenReturn(const Duration(seconds: 10));

      await service.previous();

      expect(
        service.playbackData.currentTrack,
        equals(track2),
      ); // Track unchanged
      verify(() => mockDriver.seek(Duration.zero)).called(1);
    });

    test('previous moves to previous track if position <= 3 seconds', () async {
      await service.playQueue([track1, track2], index: 1);

      // Simulate playback just started
      when(() => mockDriver.position).thenReturn(const Duration(seconds: 1));

      await service.previous();

      expect(service.playbackData.currentTrack, equals(track1));
      expect(service.playbackData.queue.currentIndex, equals(0));
    });

    test(
      'auto-advance triggers next when processingState completed and playing',
      () async {
        await service.playQueue([track1, track2], index: 0);

        // Simulate natural playback end
        when(() => mockDriver.isPlaying).thenReturn(true);
        processingController.add(PlaybackProcessingState.completed);

        // Yield to allow stream listener to process the event
        await Future<void>.delayed(Duration.zero);

        expect(service.playbackData.currentTrack, equals(track2));
        expect(service.playbackData.queue.currentIndex, equals(1));
      },
    );

    test('togglePlayPause pauses when playing and plays when paused', () async {
      when(() => mockDriver.isPlaying).thenReturn(true);
      await service.togglePlayPause();
      verify(() => mockDriver.pause()).called(1);

      when(() => mockDriver.isPlaying).thenReturn(false);
      await service.togglePlayPause();
      verify(() => mockDriver.play()).called(1);
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
        expect(service.playbackData.queue.repeatMode, equals(RepeatMode.all));
      },
    );
  });
}
