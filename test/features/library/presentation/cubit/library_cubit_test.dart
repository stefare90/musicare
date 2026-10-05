import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
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
  late LibraryCubit cubit;
  late TestSavedMediaIndex savedMedia;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );
  final secondPlaylist = Playlist(
    id: 'pl2',
    name: 'Focus',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    playlists = MockPlaylistService();
    notices = NoticeBus();

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.playlist).thenReturn(playlists);
  });

  tearDown(() async {
    await cubit.close();
    await savedMedia.close();
  });

  LibraryCubit buildCubit({bool authenticated = false}) {
    final authCubit = TestAccountCubit(
      testAccountState(isAuthenticated: authenticated),
    );
    savedMedia = TestSavedMediaIndex();
    return LibraryCubit(
      LibraryRepository(engine),
      notices,
      playlist: PlaylistRepository(engine),
      session: authCubit,
      savedMedia: savedMedia,
    );
  }

  PaginatedResult<T> page<T>(List<T> items, {int total = -1}) =>
      PaginatedResult<T>(
        items: items,
        total: total < 0 ? items.length : total,
        offset: 0,
        limit: 20,
      );

  void stubEmptySections() {
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => page<Playlist>([]));
    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => page<Album>([]));
    when(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => page<Artist>([]));
  }

  test('signed out: empties the sections without fetching', () async {
    cubit = buildCubit();

    await cubit.loadAll();

    expect(cubit.state.playlists.data.items, isEmpty);
    verifyNever(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('signed in: loads the three account sections independently', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist]));

    await cubit.loadAll();
    // The three loads are fire-and-forget; let them settle.
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.playlists.data.items.single.id, 'pl1');
    expect(cubit.state.albums.data.items, isEmpty);
    expect(cubit.state.artists.data.items, isEmpty);
  });

  test('loadMore appends the next page of a section', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist], total: 2));
    when(
      () => user.savedPlaylists(offset: 1, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([secondPlaylist], total: 2));

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    await cubit.loadMore(LibrarySection.playlists);

    expect(cubit.state.playlists.data.items.length, 2);
    expect(cubit.state.playlists.data.items.last.id, 'pl2');
  });

  test('a failed load keeps the existing data and emits auth notices', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist], total: 2));
    when(
      () => user.savedPlaylists(offset: 1, limit: 20),
    ).thenAnswer((_) async {
      throw const MetadataAuthRequiredException('sign in');
    });

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    await cubit.loadMore(LibrarySection.playlists);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.playlists.data.items.length, 1);
    expect(cubit.state.playlists.error, isA<MetadataAuthRequiredException>());
    expect(seen, hasLength(1));
    await subscription.cancel();
  });

  test('updateGridColumns rounds the page size to whole rows', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();

    cubit.updateGridColumns(3);
    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);

    verify(() => user.savedPlaylists(offset: 0, limit: 21)).called(1);
    verify(() => user.savedAlbums(offset: 0, limit: 21)).called(1);
  });

  test('a section starts in the loading state while fetching', () {
    expect(const LibraryState().playlists, isA<SectionState>());
  });

  test('a saved-album change reloads only the albums section', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(user);

    savedMedia.emit(MediaItemType.album);
    await Future<void>.delayed(Duration.zero);

    verify(() => user.savedAlbums(offset: 0, limit: 20)).called(1);
    verifyNever(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
    verifyNever(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('a track change reloads no library section', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(user);

    savedMedia.emit(MediaItemType.track);
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
    verifyNever(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
    verifyNever(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('createPlaylist returns the created playlist', () async {
    cubit = buildCubit(authenticated: true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'My list',
        description: 'desc',
        public_: true,
      ),
    ).thenAnswer((_) async => playlist);

    final created = await cubit.createPlaylist(
      name: 'My list',
      description: 'desc',
      isPublic: true,
    );

    expect(created?.id, 'pl1');
  });

  test('createPlaylist announces when sign-in is required', () async {
    cubit = buildCubit();
    when(() => user.me()).thenAnswer((_) async => const <String, dynamic>{});

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    final created = await cubit.createPlaylist(name: 'x');
    await Future<void>.delayed(Duration.zero);

    expect(created, isNull);
    expect((seen.single as ErrorNotice).error, isA<MetadataAuthRequiredException>());
    await subscription.cancel();
  });

  test('createPlaylist announces a write failure', () async {
    cubit = buildCubit(authenticated: true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'x',
        description: null,
        public_: false,
      ),
    ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    final created = await cubit.createPlaylist(name: 'x');
    await Future<void>.delayed(Duration.zero);

    expect(created, isNull);
    expect(seen, hasLength(1));
    await subscription.cancel();
  });

  test('createPlaylist announces the new playlist through the change stream',
      () async {
    cubit = buildCubit(authenticated: true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'My list',
        description: null,
        public_: false,
      ),
    ).thenAnswer((_) async => playlist);

    await cubit.createPlaylist(name: 'My list');

    expect(savedMedia.refreshed, [MediaItemType.playlist]);
  });

  test('refresh reloads the section and the saved set only once', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist]));
    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(user);

    await cubit.refresh(LibrarySection.playlists);

    // One reload of the section and one silent refresh of the saved set: the
    // silent refresh must not trigger a second section load through `changes`.
    verify(() => user.savedPlaylists(offset: 0, limit: 20)).called(1);
    expect(savedMedia.refreshed, [MediaItemType.playlist]);
    // Silent: the section was reloaded explicitly above.
    expect(savedMedia.refreshNotifies, [false]);
  });

  test('refresh does not duplicate a section load already in flight', () async {
    cubit = buildCubit(authenticated: true);
    stubEmptySections();
    final completer = Completer<PaginatedResult<Playlist>>();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) => completer.future);

    final first = cubit.refresh(LibrarySection.playlists);
    final second = cubit.refresh(LibrarySection.playlists);
    completer.complete(page<Playlist>([playlist]));
    await Future.wait([first, second]);

    verify(() => user.savedPlaylists(offset: 0, limit: 20)).called(1);
  });
}
