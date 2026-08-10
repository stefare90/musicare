import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iplaylist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/details/playlist/presentation/pages/playlist_page.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class MockPluginEngine extends Mock implements PluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockPlaylistService mockPlaylist;

  final testPlaylist = Playlist(
    id: 'pl1',
    name: 'Top 50 Hits',
    description: 'Best songs',
    externalUri: '',
    owner: User(id: 'u1', name: 'Spotify', externalUri: ''),
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockPlaylist = MockPlaylistService();

    sl.registerLazySingleton<PluginEngine>(() => mockEngine);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.playlist).thenReturn(mockPlaylist);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlaylistPage(playlist: testPlaylist),
    );
  }

  group('PlaylistPage Widget Tests', () {
    testWidgets('renders playlist header with title and owner', (tester) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Top 50 Hits'), findsNWidgets(2)); // Header + AppBar
      expect(find.text('Spotify'), findsOneWidget);
    });
  });
}
