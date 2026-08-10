import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/ialbum.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/details/album/presentation/pages/album_page.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class MockPluginEngine extends Mock implements PluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockAlbumService extends Mock implements IAlbum {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockAlbumService mockAlbum;

  final testAlbum = Album(
    id: 'al1',
    name: 'Abbey Road',
    artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
    images: [],
    releaseDate: '1969',
    externalUri: '',
    totalTracks: 17,
    albumType: AlbumType.album,
  );

  final testTrack = Track(
    id: 't1',
    name: 'Come Together',
    externalUri: '',
    artists: testAlbum.artists,
    album: testAlbum,
    durationMs: 259000,
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockAlbum = MockAlbumService();

    sl.registerLazySingleton<PluginEngine>(() => mockEngine);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.album).thenReturn(mockAlbum);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AlbumPage(album: testAlbum),
    );
  }

  group('AlbumPage Widget Tests', () {
    testWidgets('renders album header and track list', (tester) async {
      when(() => mockAlbum.getAlbum('al1')).thenAnswer((_) async => testAlbum);
      when(() => mockAlbum.tracks('al1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 17,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Abbey Road'), findsNWidgets(2)); // Header + AppBar
      expect(
        find.text('The Beatles'),
        findsNWidgets(2),
      ); // Header Subtitle + Track Tile Subtitle
      expect(find.text('Come Together'), findsOneWidget);
    });
  });
}
