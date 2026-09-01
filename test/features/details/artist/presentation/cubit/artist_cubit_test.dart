import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iartist.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
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

      cubit = ArtistCubit(mockPluginEngine, initialArtist);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state holds initial artist', () {
      expect(cubit.state.artist, equals(initialArtist));
      expect(cubit.state.isSaved, isFalse);
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

    test(
      'toggleSave updates isSaved state and calls plugin save/unsave',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.artist).thenReturn(mockArtistService);
        when(() => mockArtistService.save(['a1'])).thenAnswer((_) async {});
        when(() => mockArtistService.unsave(['a1'])).thenAnswer((_) async {});

        await cubit.toggleSave();
        expect(cubit.state.isSaved, isTrue);
        verify(() => mockArtistService.save(['a1'])).called(1);

        await cubit.toggleSave();
        expect(cubit.state.isSaved, isFalse);
        verify(() => mockArtistService.unsave(['a1'])).called(1);
      },
    );
  });
}
