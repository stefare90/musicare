import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

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
    registerFallbackValue(createTestTrack('fallback', 'fallback'));
  });

  group('PlayerCubit Pure Service Delegate Tests', () {
    late MockAudioPlayerService mockAudioService;
    late PlayerCubit cubit;

    late StreamController<PlaybackData> snapshotController;
    final track1 = createTestTrack('1', 'Song 1');

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      snapshotController = StreamController<PlaybackData>.broadcast();

      when(
        () => mockAudioService.playbackDataStream,
      ).thenAnswer((_) => snapshotController.stream);

      // Default initial data
      when(
        () => mockAudioService.playbackData,
      ).thenReturn(const PlaybackData());

      // Mock setup for the split methods
      when(() => mockAudioService.playTrack(any())).thenAnswer((_) async {});
      when(
        () => mockAudioService.playQueue(any(), index: any(named: 'index')),
      ).thenAnswer((_) async {});

      when(() => mockAudioService.next()).thenAnswer((_) async {});
      when(() => mockAudioService.previous()).thenAnswer((_) async {});
      when(() => mockAudioService.togglePlayPause()).thenAnswer((_) async {});
      when(() => mockAudioService.toggleShuffle()).thenReturn(null);
      when(() => mockAudioService.dispose()).thenAnswer((_) async {});

      cubit = PlayerCubit(audioService: mockAudioService);
    });

    tearDown(() async {
      await snapshotController.close();
      await cubit.close();
    });

    test(
      'initial state has empty queue and idle state mapped from PlaybackData',
      () {
        expect(
          cubit.state.processingState,
          equals(PlaybackProcessingState.idle),
        );
        expect(cubit.state.queue.isEmpty, isTrue);
      },
    );

    test(
      'maps new PlaybackData emitted by the service into PlayerState',
      () async {
        final newData = PlaybackData(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: const PlaybackQueue().setQueue([track1]),
        );

        snapshotController.add(newData);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(cubit.state.isPlaying, isTrue);
        expect(
          cubit.state.processingState,
          equals(PlaybackProcessingState.ready),
        );
        expect(cubit.state.queue.currentTrack, equals(track1));
      },
    );

    test('delegates playTrack call directly to service', () async {
      await cubit.playTrack(track1);

      verify(() => mockAudioService.playTrack(track1)).called(1);
    });

    test('delegates playQueue call directly to service', () async {
      final queue = [track1];
      await cubit.playQueue(queue, index: 0);

      verify(() => mockAudioService.playQueue(queue, index: 0)).called(1);
    });

    test(
      'delegates next and togglePlayPause calls directly to service',
      () async {
        await cubit.next();
        verify(() => mockAudioService.next()).called(1);

        await cubit.togglePlayPause();
        verify(() => mockAudioService.togglePlayPause()).called(1);
      },
    );

    test('delegates toggleShuffle call directly to service', () {
      cubit.toggleShuffle();
      verify(() => mockAudioService.toggleShuffle()).called(1);
    });
  });
}
