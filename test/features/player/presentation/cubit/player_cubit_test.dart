import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockAudioStreamResolver extends Mock implements AudioStreamResolver {}

class FakeAudioSource extends Fake implements ja.AudioSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAudioSource());
  });

  group('PlayerCubit Unit Tests', () {
    late MockAudioPlayerService mockAudioService;
    late MockAudioStreamResolver mockResolver;
    late PlayerCubit cubit;

    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;
    late StreamController<ja.PlayerState> playerStateController;

    final testTrack = Track(
      id: 't1',
      name: 'Come Together',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 259000,
    );

    const testCandidate = AudioStreamResponse(
      url: 'https://cdn.example.com/audio.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      mockResolver = MockAudioStreamResolver();

      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();
      playerStateController = StreamController<ja.PlayerState>.broadcast();

      when(
        () => mockAudioService.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        () => mockAudioService.durationStream,
      ).thenAnswer((_) => durationController.stream);
      when(
        () => mockAudioService.playerStateStream,
      ).thenAnswer((_) => playerStateController.stream);

      when(
        () => mockAudioService.setAudioSource(any()),
      ).thenAnswer((_) async {});
      when(() => mockAudioService.play()).thenAnswer((_) async {});
      when(() => mockAudioService.pause()).thenAnswer((_) async {});
      when(() => mockAudioService.dispose()).thenAnswer((_) async {});

      cubit = PlayerCubit(
        audioService: mockAudioService,
        resolver: mockResolver,
      );
    });

    tearDown(() async {
      await positionController.close();
      await durationController.close();
      await playerStateController.close();
      await cubit.close();
    });

    test('initial state has idle status and null currentTrack', () {
      expect(cubit.state.status, equals(PlayerStatus.idle));
      expect(cubit.state.currentTrack, isNull);
      expect(cubit.state.isPlaying, isFalse);
    });

    test(
      'playTrack resolves stream, loads audio source, and starts playback',
      () async {
        final resolved = ResolvedPlaybackTrack(
          track: testTrack,
          candidates: [testCandidate],
        );

        when(
          () => mockResolver.resolveTrack(testTrack),
        ).thenAnswer((_) async => resolved);
        when(
          () => mockResolver.createAudioSource(resolved),
        ).thenReturn(FakeAudioSource());

        await cubit.playTrack(testTrack);

        expect(cubit.state.currentTrack, equals(testTrack));
        verify(() => mockAudioService.setAudioSource(any())).called(1);
        verify(() => mockAudioService.play()).called(1);
      },
    );

    test('playTrack retries with candidate #2 if candidate #1 fails', () async {
      const candidate2 = AudioStreamResponse(
        url: 'https://cdn2.example.com/audio2.m4a',
        quality: AudioQuality.high,
        bitrate: 128000,
      );

      final resolved = ResolvedPlaybackTrack(
        track: testTrack,
        candidates: [testCandidate, candidate2],
      );

      when(
        () => mockResolver.resolveTrack(testTrack),
      ).thenAnswer((_) async => resolved);
      when(
        () => mockResolver.createAudioSource(resolved),
      ).thenReturn(FakeAudioSource());

      var attempts = 0;
      when(() => mockAudioService.setAudioSource(any())).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw Exception('CDN 403 Forbidden');
        }
      });

      await cubit.playTrack(testTrack);

      expect(attempts, equals(2));
      expect(resolved.currentCandidateIndex, equals(1));
      expect(cubit.state.status, isNot(PlayerStatus.error));
      verify(() => mockAudioService.play()).called(1);
    });

    test(
      'togglePlayPause pauses when playing and resumes when paused',
      () async {
        cubit.emit(cubit.state.copyWith(status: PlayerStatus.playing));
        await cubit.togglePlayPause();
        verify(() => mockAudioService.pause()).called(1);

        cubit.emit(cubit.state.copyWith(status: PlayerStatus.paused));
        await cubit.togglePlayPause();
        verify(() => mockAudioService.play()).called(1);
      },
    );
  });
}
