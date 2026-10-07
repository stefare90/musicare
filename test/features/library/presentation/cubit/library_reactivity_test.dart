import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockPlaylistService playlists;
  late NoticeBus notices;
  late TestUserCubit userCubit;
  late LibraryCubit library;
  late AddToPlaylistCubit addToPlaylist;

  final existing = Playlist(
    id: 'pl1',
    name: 'Existing',
    description: '',
    externalUri: '',
    owner: const User(id: 'me', name: 'me', externalUri: ''),
  );
  final created = Playlist(
    id: 'pl2',
    name: 'Fresh',
    description: '',
    externalUri: '',
    owner: const User(id: 'me', name: 'me', externalUri: ''),
  );

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    playlists = MockPlaylistService();
    notices = NoticeBus();
    userCubit = TestUserCubit(
      testUserState(isAuthenticated: true, userId: 'me'),
    );

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.playlist).thenReturn(playlists);

    when(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Track>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Album>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Artist>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Playlist>(
        items: [existing],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );

    library = LibraryCubit(
      LibraryRepository(engine),
      notices,
      playlist: PlaylistRepository(engine),
      session: userCubit,
      savedMedia: userCubit,
    );
    addToPlaylist = AddToPlaylistCubit(
      LibraryRepository(engine),
      PlaylistRepository(engine),
      notices,
      session: userCubit,
      savedMedia: userCubit,
      edits: userCubit,
    );
  });

  tearDown(() async {
    await addToPlaylist.close();
    await library.close();
    await userCubit.close();
  });

  test('creating a playlist from the sheet reloads the library tab', () async {
    await library.loadAll();
    // Let the loads and the warm-up settle.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(library.state.playlists.data.items.map((p) => p.id), ['pl1']);

    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Playlist>(
        items: [existing, created],
        total: 2,
        offset: 0,
        limit: 100,
      ),
    );
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'Fresh',
        description: null,
        public_: false,
      ),
    ).thenAnswer((_) async => created);
    when(() => playlists.addTracks('pl2', ['t1'])).thenAnswer(
      (_) async => const AddTracksResult(added: 1, alreadyPresent: []),
    );

    await addToPlaylist.createPlaylist(name: 'Fresh', trackIds: ['t1']);
    // The fake records the refresh instead of announcing it (covered in
    // `user_cubit_test`).
    userCubit.pushSavedChange(MediaItemType.playlist);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(
      library.state.playlists.data.items.map((p) => p.id),
      contains('pl2'),
    );
  });
}
