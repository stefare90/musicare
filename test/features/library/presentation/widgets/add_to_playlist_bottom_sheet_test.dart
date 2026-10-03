import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockPlaylistService playlistService;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill Vibes',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );

  final track = Track(
    id: 't1',
    name: 'Song A',
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 180000,
  );

  setUp(() async {
    await sl.reset();

    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    playlistService = MockPlaylistService();

    sl.registerLazySingleton<LibraryRepository>(() => LibraryRepository(engine));
    sl.registerLazySingleton<PlaylistRepository>(
      () => PlaylistRepository(engine),
    );
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.playlist).thenReturn(playlistService);
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Playlist>(
        items: [playlist],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddToPlaylistBottomSheet.show(context, track),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a playlist adds the track', (tester) async {
    when(() => playlistService.addTracks('pl1', ['t1'])).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chill Vibes'));
    await tester.pumpAndSettle();

    verify(() => playlistService.addTracks('pl1', ['t1'])).called(1);
    expect(find.text('Added to Chill Vibes'), findsOneWidget);
  });
}
