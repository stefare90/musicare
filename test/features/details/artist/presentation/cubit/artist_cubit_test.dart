import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockArtistService extends Mock implements IArtist {}

void main() {
  group('ArtistCubit Unit Tests', () {
    late MockPluginEngine mockPluginEngine;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockArtistService mockArtistService;
    late NoticeBus noticeBus;
    late ArtistCubit cubit;

    final initialArtist = Artist(
      id: 'a1',
      name: 'The Beatles',
      externalUri: '',
    );

    final fullArtist = Artist(
      id: 'a1',
      name: 'The Beatles',
      externalUri: '',
      genres: ['Rock', 'Pop'],
    );

    Track createTrack(String id, String name) {
      return Track(
        id: id,
        name: name,
        externalUri: '',
        artists: [initialArtist],
        album: Album(
          id: 'al1',
          name: 'Single',
          artists: [],
          releaseDate: '',
          externalUri: '',
          totalTracks: 1,
          albumType: AlbumType.single,
        ),
        durationMs: 431000,
      );
    }

    final testAlbum = Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [initialArtist],
      releaseDate: '1969',
      externalUri: '',
      totalTracks: 17,
      albumType: AlbumType.album,
    );

    setUp(() {
      mockPluginEngine = MockPluginEngine();
      mockMetadataPlugin = MockMetadataPlugin();
      mockArtistService = MockArtistService();

      noticeBus = NoticeBus();
      cubit = ArtistCubit(MediaRepository(mockPluginEngine), noticeBus, initialArtist);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state holds initial artist', () {
      expect(cubit.state.artist, equals(initialArtist));
    });

    test(
      'loadArtist sets error on all sections if metadata plugin is missing',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(false);

        await cubit.loadArtist();

        expect(cubit.state.isTotalFailure, isTrue);
        expect(cubit.state.firstError, isNotNull);
      },
    );

    test(
      'loadArtist fetches full artist, top tracks (limit 6), albums and related artists',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.artist).thenReturn(mockArtistService);

        when(
          () => mockArtistService.getArtist('a1'),
        ).thenAnswer((_) async => fullArtist);

        when(
          () => mockArtistService.topTracks('a1', offset: 0, limit: 6),
        ).thenAnswer(
          (_) async => PaginatedResult(
            items: [createTrack('t1', 'Hey Jude')],
            total: 10,
            offset: 0,
            limit: 6,
          ),
        );

        when(
          () => mockArtistService.albums('a1', offset: 0, limit: 6),
        ).thenAnswer(
          (_) async => PaginatedResult(
            items: [testAlbum],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );

        when(
          () => mockArtistService.related('a1', offset: 0, limit: 6),
        ).thenAnswer(
          (_) async => PaginatedResult(
            items: [initialArtist],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );

        await cubit.loadArtist();
        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.artist.genres, contains('Rock'));
        expect(cubit.state.topTracks.data.items.length, equals(1));
        expect(cubit.state.albums.data.items.length, equals(1));
        expect(cubit.state.related.data.items.length, equals(1));
        expect(cubit.state.hasAnyDataLoaded, isTrue);
      },
    );

    test('fetchMoreTopTracks appends next chunk of tracks', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.artist).thenReturn(mockArtistService);

      when(
        () => mockArtistService.getArtist('a1'),
      ).thenAnswer((_) async => fullArtist);

      when(
        () => mockArtistService.topTracks('a1', offset: 0, limit: 6),
      ).thenAnswer(
        (_) async => PaginatedResult(
          items: [createTrack('t1', 'Track 1')],
          total: 2,
          offset: 0,
          limit: 6,
        ),
      );

      when(
        () => mockArtistService.albums('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => const PaginatedResult.empty());

      when(
        () => mockArtistService.related('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => const PaginatedResult.empty());

      when(
        () => mockArtistService.topTracks('a1', offset: 1, limit: 6),
      ).thenAnswer(
        (_) async => PaginatedResult(
          items: [createTrack('t2', 'Track 2')],
          total: 2,
          offset: 1,
          limit: 6,
        ),
      );

      await cubit.loadArtist();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.topTracks.data.items.length, equals(1));

      await cubit.fetchMoreTopTracks(limit: 6);
      expect(cubit.state.topTracks.data.items.length, equals(2));
      expect(cubit.state.topTracks.data.items[1].name, equals('Track 2'));
    });

    test('a section fetch emits a notice when it needs one', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.artist).thenReturn(mockArtistService);
      final error = const MetadataAuthRequiredException('sign in');
      when(
        () => mockArtistService.topTracks('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw error);

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      cubit.fetchTopTracks();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notices, hasLength(1));
      expect(notices.single, same(error));
      await subscription.cancel();
    });

    test('a section fetch stays silent for non-notifiable errors', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.artist).thenReturn(mockArtistService);
      when(
        () => mockArtistService.topTracks('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('network'));

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      cubit.fetchTopTracks();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notices, isEmpty);
      await subscription.cancel();
    });
  });
}
