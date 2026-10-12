import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/models/playback_pending.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

Track createPendingCubitTrack(String id, String name) {
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
    registerFallbackValue(createPendingCubitTrack('fb', 'fb'));
    registerFallbackValue(
      PendingSource(
        loader: (_) async => const PaginatedResult<Track>(
          items: [],
          total: 0,
          offset: 0,
          limit: 20,
        ),
        nextOffset: 0,
        total: 0,
      ),
    );
  });

  group('PlayerCubit pending source (S2)', () {
    late MockAudioPlayerService mockService;
    late NoticeBus notices;
    late PlayerCubit cubit;
    late StreamController<PlaybackData> snapshots;

    final track = createPendingCubitTrack('1', 'Song 1');

    setUp(() {
      mockService = MockAudioPlayerService();
      notices = NoticeBus();
      snapshots = StreamController<PlaybackData>.broadcast();

      when(
        () => mockService.playbackDataStream,
      ).thenAnswer((_) => snapshots.stream);
      when(
        () => mockService.playbackData,
      ).thenReturn(const PlaybackData());

      cubit = PlayerCubit(mockService, notices);
    });

    tearDown(() async {
      await snapshots.close();
      await cubit.close();
    });

    test('playQueue forwards the pending source to the service', () async {
      final pending = PendingSource(
        loader: (_) async => PaginatedResult<Track>(
          items: [track],
          total: 2,
          offset: 1,
          limit: 20,
        ),
        nextOffset: 1,
        total: 2,
      );
      when(
        () => mockService.playQueue(
          any(),
          index: any(named: 'index'),
          pending: any(named: 'pending'),
        ),
      ).thenAnswer((_) async {});

      await cubit.playQueue([track], index: 0, pending: pending);

      final captured =
          verify(
                () => mockService.playQueue(
                  any(),
                  index: 0,
                  pending: captureAny(named: 'pending'),
                ),
              ).captured.single
              as PendingSource?;
      expect(identical(captured, pending), isTrue);
    });

    test('playQueue without pending forwards null', () async {
      when(
        () => mockService.playQueue(
          any(),
          index: any(named: 'index'),
          pending: any(named: 'pending'),
        ),
      ).thenAnswer((_) async {});

      await cubit.playQueue([track]);

      final captured =
          verify(
                () => mockService.playQueue(
                  any(),
                  index: 0,
                  pending: captureAny(named: 'pending'),
                ),
              ).captured.single
              as PendingSource?;
      expect(captured, isNull);
    });

    test('retryPendingLoad delegates to the service', () async {
      when(() => mockService.retryPendingLoad()).thenAnswer((_) async {});

      await cubit.retryPendingLoad();

      verify(() => mockService.retryPendingLoad()).called(1);
    });

    test('state carries the pending snapshot', () async {
      snapshots.add(
        const PlaybackData(
          pending: PlaybackPending(nextOffset: 8, total: 50, isLoading: true),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.pending.remaining, equals(42));
      expect(cubit.state.pending.isLoading, isTrue);
      expect(cubit.state.pending.error, isNull);
    });

    test('a pending error emits one notice until it clears', () async {
      final seen = <Notice>[];
      final subscription = notices.notices.listen(seen.add);
      addTearDown(subscription.cancel);

      PlaybackPending pending() =>
          const PlaybackPending(nextOffset: 0, total: 1);
      PlaybackPending failed() => PlaybackPending(
        nextOffset: 0,
        total: 1,
        error: PendingLoadException(Exception('down')),
      );

      snapshots.add(PlaybackData(pending: pending()));
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);

      snapshots.add(PlaybackData(pending: failed()));
      await Future<void>.delayed(Duration.zero);
      expect(seen.whereType<ErrorNotice>(), hasLength(1));

      snapshots.add(PlaybackData(pending: failed()));
      await Future<void>.delayed(Duration.zero);
      expect(seen.whereType<ErrorNotice>(), hasLength(1));

      snapshots.add(PlaybackData(pending: pending()));
      await Future<void>.delayed(Duration.zero);

      snapshots.add(PlaybackData(pending: failed()));
      await Future<void>.delayed(Duration.zero);
      expect(seen.whereType<ErrorNotice>(), hasLength(2));
    });
  });
}
