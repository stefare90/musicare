import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iartist.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/features/details/artist/presentation/pages/artist_page.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockArtistService extends Mock implements IArtist {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockArtistService mockArtist;

  final testArtist = Artist(id: 'a1', name: 'The Beatles', externalUri: '');

  final testTrack = Track(
    id: 't1',
    name: 'Yesterday',
    externalUri: '',
    artists: [testArtist],
    album: Album(
      id: 'al1',
      name: 'Help!',
      artists: [],
      releaseDate: '1965',
      externalUri: '',
      totalTracks: 14,
      albumType: AlbumType.album,
    ),
    durationMs: 125000,
  );

  final testAlbum = Album(
    id: 'al1',
    name: 'Abbey Road',
    artists: [testArtist],
    releaseDate: '1969',
    externalUri: '',
    totalTracks: 17,
    albumType: AlbumType.album,
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockArtist = MockArtistService();

    sl.registerLazySingleton<MetadataPluginEngine>(() => mockEngine);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.artist).thenReturn(mockArtist);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ArtistPage(artist: testArtist),
    );
  }

  group('ArtistPage Widget Tests', () {
    testWidgets(
      'renders artist header, TrackMatrix popular tracks, discography and related sections',
      (tester) async {
        when(
          () => mockArtist.getArtist('a1'),
        ).thenAnswer((_) async => testArtist);
        when(() => mockArtist.topTracks('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );
        when(() => mockArtist.albums('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testAlbum],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );
        when(() => mockArtist.related('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testArtist],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('The Beatles'), findsWidgets);
        expect(find.text('Popular Tracks'), findsOneWidget);
        expect(find.byType(TrackMatrix), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
        expect(find.text('Discography'), findsOneWidget);
        expect(find.text('Abbey Road'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Fans Also Like'),
          300.0,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Fans Also Like'), findsOneWidget);
      },
    );

    testWidgets('renders ErrorCard when all sections fail', (tester) async {
      when(
        () => mockArtist.getArtist('a1'),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.topTracks('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.albums('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.related('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('An unexpected error occurred: API error'),
        findsOneWidget,
      );
    });
  });
}
