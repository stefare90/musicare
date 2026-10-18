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

Track _track(String id) {
  return Track(
    id: id,
    name: 'Track $id',
    externalUri: '',
    artists: [Artist(id: 'artist-$id', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'album-$id',
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

PlaybackData _ended(List<Track> tracks, {int? index}) {
  return PlaybackData(
    queue: PlaybackQueue(
      tracks: List.unmodifiable(tracks),
      originalTracks: List.unmodifiable(tracks),
      currentIndex: index ?? tracks.length - 1,
    ),
    processingState: PlaybackProcessingState.completed,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_track('fallback'));
  });

  group('PlayerCubit radio', () {
    late MockAudioPlayerService service;
    late MockMediaRepository media;
    late MockUserSession user;
    late MockPreferencesService preferences;
    late NoticeBus bus;
    late PlayerCubit cubit;
    late StreamController<PlaybackData> snapshots;
    late PlaybackData live;
    late List<Notice> notices;

    final seed = _track('seed');
    final other = _track('other');
    final third = _track('third');

    setUp(() {
      service = MockAudioPlayerService();
      media = MockMediaRepository();
      user = MockUserSession();
      preferences = MockPreferencesService();
      bus = NoticeBus();
      snapshots = StreamController<PlaybackData>.broadcast();
      live = const PlaybackData();

      when(() => service.playbackDataStream).thenAnswer((_) => snapshots.stream);
      when(() => service.playbackData).thenAnswer((_) => live);
      when(
        () => service.playQueue(any(), index: any(named: 'index')),
      ).thenAnswer((_) async {});
      when(() => service.playTrack(any())).thenAnswer((_) async {});
      when(() => service.next()).thenAnswer((_) async {});
      when(() => service.rewindAndPause()).thenAnswer((_) async {});
      when(() => user.isAuthenticated).thenReturn(true);
      when(() => preferences.getInfiniteMusic()).thenReturn(true);

      notices = [];
      bus.notices.listen(notices.add);

      cubit = PlayerCubit(
        service,
        bus,
        media: media,
        user: user,
        preferences: preferences,
      );
    });

    tearDown(() async {
      await snapshots.close();
      await cubit.close();
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    group('start radio', () {
      test('replaces the queue with the seed plus its batch', () async {
        when(
          () => media.radio(seed.id),
        ).thenAnswer((_) async => [other, third]);

        await cubit.startRadio(seed);

        final queued =
            verify(
                  () => service.playQueue(captureAny(), index: 0),
                ).captured.single
                as List<Track>;
        expect(queued.map((track) => track.id), ['seed', 'other', 'third']);
      });

      test('keeps one copy of a seed returned by the provider', () async {
        when(
          () => media.radio(seed.id),
        ).thenAnswer((_) async => [other, seed, other, third]);

        await cubit.startRadio(seed);

        final queued =
            verify(
                  () => service.playQueue(captureAny(), index: 0),
                ).captured.single
                as List<Track>;
        expect(queued.map((track) => track.id), ['seed', 'other', 'third']);
      });

      test('asks to sign in instead of starting when signed out', () async {
        when(() => user.isAuthenticated).thenReturn(false);

        await cubit.startRadio(seed);
        await settle();

        expect(notices.single, isA<ErrorNotice>());
        expect(
          (notices.single as ErrorNotice).error,
          isA<MetadataAuthRequiredException>(),
        );
        verifyNever(() => media.radio(any()));
        verifyNever(() => service.playQueue(any(), index: any(named: 'index')));
      });

      test('reports a provider failure without touching the queue', () async {
        when(() => media.radio(seed.id)).thenThrow(Exception('provider down'));

        await cubit.startRadio(seed);
        await settle();

        expect(notices.single, isA<ErrorNotice>());
        verifyNever(() => service.playQueue(any(), index: any(named: 'index')));
      });
    });

    group('continuous playback', () {
      test('appends the radio batch and keeps playing at the end', () async {
        live = _ended([seed]);
        when(
          () => media.radio(seed.id),
        ).thenAnswer((_) async => [other, third]);

        snapshots.add(live);
        await settle();

        verify(() => service.addAllToQueue([other, third])).called(1);
        verify(() => service.next()).called(1);
        verifyNever(() => service.rewindAndPause());
      });

      test('drops tracks already in the queue', () async {
        live = _ended([seed, other]);
        when(
          () => media.radio(other.id),
        ).thenAnswer((_) async => [seed, third]);

        snapshots.add(live);
        await settle();

        verify(() => service.addAllToQueue([third])).called(1);
      });

      test('chains a new seed once the appended batch ends', () async {
        live = _ended([seed]);
        when(
          () => media.radio(seed.id),
        ).thenAnswer((_) async => [other]);
        snapshots.add(live);
        await settle();

        live = PlaybackData(
          queue: live.queue,
          processingState: PlaybackProcessingState.ready,
        );
        snapshots.add(live);
        await settle();

        live = _ended([seed, other]);
        when(
          () => media.radio(other.id),
        ).thenAnswer((_) async => [third]);
        snapshots.add(live);
        await settle();

        verify(() => media.radio(seed.id)).called(1);
        verify(() => media.radio(other.id)).called(1);
        verify(() => service.addAllToQueue([third])).called(1);
      });

      test('requests the batch once per finished track', () async {
        live = _ended([seed]);
        when(() => media.radio(seed.id)).thenAnswer((_) async => [other]);

        snapshots.add(live);
        await settle();
        snapshots.add(live);
        await settle();

        verify(() => media.radio(seed.id)).called(1);
      });

      test('extends again when the same track is replayed and ends', () async {
        live = _ended([seed]);
        when(() => media.radio(seed.id)).thenAnswer((_) async => [other]);
        snapshots.add(live);
        await settle();

        live = PlaybackData(queue: live.queue);
        snapshots.add(live);
        await settle();
        snapshots.add(_ended([seed]));
        await settle();

        verify(() => media.radio(seed.id)).called(2);
      });

      test('stops when the provider has nothing new', () async {
        live = _ended([seed]);
        when(() => media.radio(seed.id)).thenAnswer((_) async => [seed]);

        snapshots.add(live);
        await settle();

        verifyNever(() => service.addAllToQueue(any()));
        verifyNever(() => service.next());
        verify(() => service.rewindAndPause()).called(1);
      });

      test('stops silently when the switch is off', () async {
        when(() => preferences.getInfiniteMusic()).thenReturn(false);
        live = _ended([seed]);

        snapshots.add(live);
        await settle();

        verifyNever(() => media.radio(any()));
        verifyNever(() => service.addAllToQueue(any()));
        verify(() => service.rewindAndPause()).called(1);
        expect(notices, isEmpty);
      });

      test('stops silently when signed out', () async {
        when(() => user.isAuthenticated).thenReturn(false);
        live = _ended([seed]);

        snapshots.add(live);
        await settle();

        verifyNever(() => media.radio(any()));
        verify(() => service.rewindAndPause()).called(1);
        expect(notices, isEmpty);
      });

      test('stops silently when the provider fails', () async {
        live = _ended([seed]);
        when(() => media.radio(seed.id)).thenThrow(Exception('provider down'));

        snapshots.add(live);
        await settle();

        verifyNever(() => service.addAllToQueue(any()));
        verify(() => service.rewindAndPause()).called(1);
        expect(notices, isEmpty);
      });

      test('does not extend before the queue is over', () async {
        live = PlaybackData(
          queue: PlaybackQueue(
            tracks: List.unmodifiable([seed, other]),
            originalTracks: List.unmodifiable([seed, other]),
            currentIndex: 0,
          ),
          processingState: PlaybackProcessingState.completed,
        );

        snapshots.add(live);
        await settle();

        verifyNever(() => media.radio(any()));
        verifyNever(() => service.rewindAndPause());
      });
    });
  });
}
