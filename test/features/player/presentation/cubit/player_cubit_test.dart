import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/resolved_playback_track.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockAudioStreamResolver extends Mock implements AudioStreamResolver {}

class FakeAudioSource extends Fake implements ja.AudioSource {}

class FakeResolvedPlaybackTrack extends Fake implements ResolvedPlaybackTrack {}

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
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(FakeResolvedPlaybackTrack());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(createTestTrack('fallback', 'fallback'));
  });

  group('PlayerCubit Unit Tests with Queue', () {
    late MockAudioPlayerService mockAudioService;
    late MockAudioStreamResolver mockResolver;
    late PlayerCubit cubit;

    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;
    late StreamController<ja.PlayerState> playerStateController;

    final track1 = createTestTrack('1', 'Song 1');
    final track2 = createTestTrack('2', 'Song 2');
    final track3 = createTestTrack('3', 'Song 3');

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
        () => mockAudioService.playerState,
      ).thenReturn(ja.PlayerState(true, ja.ProcessingState.ready));

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
      when(() => mockAudioService.stop()).thenAnswer((_) async {});
      when(() => mockAudioService.seek(any())).thenAnswer((_) async {});
      when(() => mockAudioService.dispose()).thenAnswer((_) async {});

      when(() => mockResolver.resolveTrack(any())).thenAnswer(
        (invocation) async => ResolvedPlaybackTrack(
          track: invocation.positionalArguments[0] as Track,
          candidates: [testCandidate],
        ),
      );
      when(
        () => mockResolver.createAudioSource(any()),
      ).thenReturn(FakeAudioSource());

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

    test('initial state has idle status, empty queue and repeat off', () {
      expect(cubit.state.status, equals(PlayerStatus.idle));
      expect(cubit.state.queue, isEmpty);
      expect(cubit.state.repeatMode, equals(RepeatMode.off));
      expect(cubit.state.isShuffled, isFalse);
    });

    test(
      'playTrack with queue initializes queue and plays starting track',
      () async {
        final queue = [track1, track2, track3];

        await cubit.playTrack(track2, queue: queue, index: 1);

        expect(cubit.state.currentTrack, equals(track2));
        expect(cubit.state.queue.length, equals(3));
        expect(cubit.state.currentIndex, equals(1));
        verify(() => mockAudioService.setAudioSource(any())).called(1);
        verify(() => mockAudioService.play()).called(1);
      },
    );

    test('next advances to next track and starts resolution', () async {
      await cubit.playTrack(track1, queue: [track1, track2]);

      await cubit.next();

      expect(cubit.state.currentTrack, equals(track2));
      expect(cubit.state.currentIndex, equals(1));
      verify(() => mockAudioService.play()).called(2);
    });

    test('previous seeks to zero if position is > 3 seconds', () async {
      await cubit.playTrack(track2, queue: [track1, track2]);
      cubit.emit(cubit.state.copyWith(position: const Duration(seconds: 10)));

      await cubit.previous();

      expect(cubit.state.currentTrack, equals(track2));
      verify(() => mockAudioService.seek(Duration.zero)).called(1);
    });

    test('previous moves to previous track if position <= 3 seconds', () async {
      await cubit.playTrack(track2, queue: [track1, track2]);
      cubit.emit(cubit.state.copyWith(position: const Duration(seconds: 1)));

      await cubit.previous();

      expect(cubit.state.currentTrack, equals(track1));
      expect(cubit.state.currentIndex, equals(0));
    });

    test('toggleShuffle and cycleRepeatMode update state', () async {
      await cubit.playTrack(track1, queue: [track1, track2, track3]);

      cubit.toggleShuffle();
      expect(cubit.state.isShuffled, isTrue);

      cubit.cycleRepeatMode();
      expect(cubit.state.repeatMode, equals(RepeatMode.all));
    });

    test('queue management methods update state queue', () async {
      await cubit.playTrack(track1, queue: [track1]);

      cubit.addToQueue(track2);
      expect(cubit.state.queue.length, equals(2));

      cubit.insertNext(track3);
      expect(cubit.state.queue[1], equals(track3));

      cubit.removeFromQueue(2);
      expect(cubit.state.queue.length, equals(2));
    });
  });
}
