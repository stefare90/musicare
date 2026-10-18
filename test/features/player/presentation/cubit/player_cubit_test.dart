import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockMediaRepository extends Mock implements MediaRepository {}

class MockUserSession extends Mock implements UserSession {}

class MockPreferencesService extends Mock implements PreferencesService {}

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
    late NoticeBus notices;
    late PlayerCubit cubit;

    late StreamController<PlaybackData> snapshotController;
    final track1 = createTestTrack('1', 'Song 1');

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      notices = NoticeBus();
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

      final media = MockMediaRepository();
      final user = MockUserSession();
      final preferences = MockPreferencesService();
      when(() => user.isAuthenticated).thenReturn(false);
      when(() => preferences.getInfiniteMusic()).thenReturn(false);

      cubit = PlayerCubit(
        mockAudioService,
        notices,
        media: media,
        user: user,
        preferences: preferences,
      );
    });

    test(
      'emits a notice when the service reports a new playback error',
      () async {
        final seen = <Notice>[];
        final subscription = notices.notices.listen(seen.add);
        addTearDown(subscription.cancel);

        snapshotController.add(PlaybackData(error: Exception('boom')));
        await Future.delayed(const Duration(milliseconds: 10));

        expect(seen, hasLength(1));
        expect(seen.single, isA<ErrorNotice>());
      },
    );

    test('does not repeat the notice for the same error instance', () async {
      final seen = <Notice>[];
      final subscription = notices.notices.listen(seen.add);
      addTearDown(subscription.cancel);

      final failed = PlaybackData(error: Exception('boom'));
      snapshotController.add(failed);
      await Future.delayed(const Duration(milliseconds: 10));
      snapshotController.add(failed);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(seen, hasLength(1));
    });

    test('notifies again after the error clears and a new one arrives', () async {
      final seen = <Notice>[];
      final subscription = notices.notices.listen(seen.add);
      addTearDown(subscription.cancel);

      snapshotController.add(PlaybackData(error: Exception('first')));
      await Future.delayed(const Duration(milliseconds: 10));
      snapshotController.add(const PlaybackData());
      await Future.delayed(const Duration(milliseconds: 10));
      snapshotController.add(PlaybackData(error: Exception('second')));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(seen, hasLength(2));
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
