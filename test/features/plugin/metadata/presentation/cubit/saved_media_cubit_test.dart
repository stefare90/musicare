import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockTrackService extends Mock implements ITrack {}

class MockAlbumService extends Mock implements IAlbum {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockTrackService tracks;
  late MockAlbumService albums;
  late NoticeBus notices;
  late TestAccountCubit authCubit;
  late SavedMediaCubit cubit;
  late List<MediaItemType> changes;
  late StreamSubscription<MediaItemType> changesSubscription;

  final track = Track(
    id: 't1',
    name: 'Song',
    externalUri: '',
    artists: const [],
    album: const Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 1000,
  );

  const album = Album(
    id: 'al1',
    name: 'Album',
    artists: [],
    releaseDate: '',
    externalUri: '',
    totalTracks: 1,
    albumType: AlbumType.album,
  );

  const originalPlaylist = Playlist(
    id: 'pl-original',
    name: 'Weekly Exploration',
    description: '',
    externalUri: '',
    owner: User(id: 'other', name: 'other', externalUri: ''),
  );

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    tracks = MockTrackService();
    albums = MockAlbumService();
    notices = NoticeBus();
    authCubit = TestAccountCubit(testAccountState());
    cubit = SavedMediaCubit(
      LibraryRepository(engine),
      notices,
      session: authCubit,
    );
    changes = [];
    changesSubscription = cubit.changes.listen(changes.add);

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.track).thenReturn(tracks);
    when(() => metadata.album).thenReturn(albums);
  });

  tearDown(() async {
    await changesSubscription.cancel();
    await cubit.close();
    await authCubit.close();
  });

  void stubEmptyLibrary() {
    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResult<Album>(items: [], total: 0, offset: 0, limit: 100),
    );
    when(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResult<Artist>(items: [], total: 0, offset: 0, limit: 100),
    );
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Playlist>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
  }

  /// Signs in with an empty saved library, so the warm-up settles the index.
  Future<void> signIn() async {
    stubEmptyLibrary();
    when(
      () => user.savedTracks(offset: 0, limit: 100),
    ).thenAnswer(
      (_) async => const PaginatedResult<Track>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    authCubit.set(testAccountState(isAuthenticated: true));
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  test('warms the saved index when the account signs in', () async {
    stubEmptyLibrary();
    when(
      () => user.savedTracks(offset: 0, limit: 100),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );

    authCubit.set(testAccountState(isAuthenticated: true));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(cubit.isTrackSaved('t1'), isTrue);
  });

  test('fetches nothing while signed out', () async {
    await Future<void>.delayed(const Duration(milliseconds: 1));

    verifyNever(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
    verifyNever(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('toggleTrack flips optimistically and rolls back on failure', () async {
    final completer = Completer<void>();
    when(() => tracks.save(['t1'])).thenAnswer((_) => completer.future);

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);

    final future = cubit.toggleTrack(track);
    expect(cubit.isTrackSaved('t1'), isTrue);

    completer.completeError(const MetadataAuthRequiredException('sign in'));
    await future;
    await Future<void>.delayed(Duration.zero);

    expect(cubit.isTrackSaved('t1'), isFalse);
    expect(seen, hasLength(1));
    await subscription.cancel();
  });

  test('toggleTrack on a saved track calls unsave', () async {
    when(() => tracks.unsave(['t1'])).thenAnswer((_) async {});
    // Seed the state as already saved.
    cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));

    await cubit.toggleTrack(track);

    expect(cubit.isTrackSaved('t1'), isFalse);
    verify(() => tracks.unsave(['t1'])).called(1);
    verifyNever(() => tracks.save(any()));
  });

  test('a playlist save re-reads the library instead of trusting the id', () async {
    final playlistService = MockPlaylistService();
    when(() => metadata.playlist).thenReturn(playlistService);
    when(() => playlistService.save('pl-original')).thenAnswer((_) async {});

    await signIn();

    // The provider saved a copy under a different id.
    const copy = Playlist(
      id: 'pl-copy',
      name: 'Weekly Exploration',
      description: '',
      externalUri: '',
      owner: User(id: 'me', name: 'me', externalUri: ''),
    );
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Playlist>(
        items: [copy],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );

    await cubit.togglePlaylist(originalPlaylist);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.playlistIds, {'pl-copy'});
  });

  test('reset clears the cached IDs', () async {
    cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));
    cubit.reset();
    expect(cubit.state.trackIds, isEmpty);
    expect(cubit.state.loaded, isEmpty);
  });

  test('drops the index when the account signs out', () async {
    cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));

    authCubit.set(testAccountState(isAuthenticated: false));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.trackIds, isEmpty);
  });

  test('the warm-up announces nothing', () async {
    stubEmptyLibrary();
    when(
      () => user.savedTracks(offset: 0, limit: 100),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );

    authCubit.set(testAccountState(isAuthenticated: true));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(cubit.state.trackIds, {'t1'});
    expect(changes, isEmpty);
  });

  test('a successful toggle announces the type', () async {
    when(() => tracks.save(['t1'])).thenAnswer((_) async {});

    await cubit.toggleTrack(track);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.isTrackSaved('t1'), isTrue);
    expect(changes, [MediaItemType.track]);
  });

  test('a failed toggle announces nothing', () async {
    when(
      () => tracks.save(['t1']),
    ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

    await cubit.toggleTrack(track);

    expect(cubit.isTrackSaved('t1'), isFalse);
    expect(changes, isEmpty);
  });

  test('refresh announces only when the saved set differs', () async {
    await signIn();
    expect(changes, isEmpty);

    await cubit.refresh(MediaItemType.album);
    await Future<void>.delayed(Duration.zero);
    expect(changes, isEmpty);

    when(
      () => user.savedAlbums(offset: 0, limit: 100),
    ).thenAnswer(
      (_) async =>
          const PaginatedResult<Album>(items: [album], total: 1, offset: 0, limit: 100),
    );
    await cubit.refresh(MediaItemType.album);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.albumIds, {'al1'});
    expect(changes, [MediaItemType.album]);
  });

  test('reset announces nothing and clears the index', () async {
    when(() => tracks.save(['t1'])).thenAnswer((_) async {});
    await cubit.toggleTrack(track);
    await Future<void>.delayed(Duration.zero);
    expect(changes, [MediaItemType.track]);

    cubit.reset();

    expect(cubit.state.trackIds, isEmpty);
    expect(changes, [MediaItemType.track]);
  });

  test('an in-flight load cannot populate the next account index', () async {
    final hanging = Completer<PaginatedResult<Album>>();
    stubEmptyLibrary();
    when(
      () => user.savedTracks(offset: 0, limit: 100),
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
    ).thenAnswer((_) => hanging.future);

    authCubit.set(testAccountState(isAuthenticated: true, userId: 'A'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    authCubit.set(testAccountState(isAuthenticated: false));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    const bAlbum = Album(
      id: 'b1',
      name: 'B Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    );
    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Album>(
        items: [bAlbum],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );
    authCubit.set(testAccountState(isAuthenticated: true, userId: 'B'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    hanging.complete(
      const PaginatedResult<Album>(
        items: [album],
        total: 1,
        offset: 0,
        limit: 100,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(cubit.state.albumIds, {'b1'});
  });
}
